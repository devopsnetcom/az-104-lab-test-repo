###########################################
# Get ALL VNETs from RG
###########################################
data "azurerm_resources" "all_vnets" {
  resource_group_name = var.rg_Name
  type                = "Microsoft.Network/virtualNetworks"
}

###########################################
# Extract only student VNET names (exclude mother)
########################################
locals {
  student_vnet_names = [
    for v in data.azurerm_resources.all_vnets.resources :
    v.name
    if lower(v.name) != lower(var.mother_vnet_name)
  ]
}

###########################################
# Fetch each student VNET
###########################################
data "azurerm_virtual_network" "student_vnets" {
  for_each = toset(local.student_vnet_names)

  name                = each.value
  resource_group_name = var.rg_Name
}

###########################################
# Extract CIDRs of all existing student VNETs
###########################################
locals {
  student_vnet_cidrs = flatten([
    for v in data.azurerm_virtual_network.student_vnets :
    v.address_space
  ])
}

###########################################
# Extract used second octets (10.X.0.0/16)
###########################################
locals {
  used_octets = length(local.student_vnet_cidrs) > 0 ? [
    for cidr in local.student_vnet_cidrs :
    tonumber(regex("^10\\.(\\d+)\\.", cidr)[0])
  ] : []
}

###########################################
# Check if CURRENT student's VNET already exists
###########################################
locals {
  current_vnet_exists = contains(local.student_vnet_names, var.vnet_Name)
}

###########################################
# Get EXISTING CIDR for CURRENT user (if exists)
###########################################
locals {
  current_vnet_existing_cidr = (
    local.current_vnet_exists ? data.azurerm_virtual_network.student_vnets[var.vnet_Name].address_space[0] : null
  )
}


###########################################
# Calculate next available octet (only for NEW vnets)
###########################################
locals {
  next_octet = (length(local.used_octets) == 0 ? 1 : max(local.used_octets...) + 1)
}

###########################################
# FINAL → Decide CIDR for this student VNET
# If exists → reuse old CIDR
# If new → assign next available range
###########################################
locals {
  next_student_vnet_cidr = (
    local.current_vnet_exists ? local.current_vnet_existing_cidr : "10.${local.next_octet}.0.0/16"
  )

  next_student_subnet1 = cidrsubnet(local.next_student_vnet_cidr, 8, 0)
  next_student_subnet2 = cidrsubnet(local.next_student_vnet_cidr, 8, 1)

  subnet_AddressList = [ local.next_student_subnet1, local.next_student_subnet2 ]
}

############################################################################################################

/* Create Student VNET and Subnets */
resource "azurerm_virtual_network" "student_vnet" {
  name                  = var.vnet_Name
  resource_group_name   = var.rg_Name
  location              = var.location
  address_space         = [local.next_student_vnet_cidr]
}

resource "azurerm_subnet" "student_subnet" {
  count                = length(var.subnet_NameList)
  name                 = var.subnet_NameList[count.index]
  virtual_network_name = azurerm_virtual_network.student_vnet.name
  resource_group_name  = var.rg_Name
  address_prefixes     = [local.subnet_AddressList[count.index]]
}

/* Both way Vnet Peering between Mother VNet and Student VNet */
resource "azurerm_virtual_network_peering" "student_to_mother" {
  name                      = "peer-${var.user_name}-to-mother"
  resource_group_name       = var.rg_Name
  virtual_network_name      = azurerm_virtual_network.student_vnet.name
  remote_virtual_network_id = var.mother_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "mother_to_student" {
  name                      = "peer-mother-to-${var.user_name}"
  resource_group_name       = var.rg_Name
  virtual_network_name      = var.mother_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.student_vnet.id
  allow_forwarded_traffic   = true
}

/*
resource "azurerm_subnet" "basion_subnet" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.wec_vnet.name
  resource_group_name  = var.rg_Name
  address_prefixes     = [var.basinton_subnet_Address[0]]
}*/


# -------------------------------
# Network Security Group (NSG)
# -------------------------------
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vnet_Name}-nsg"
  location            = var.location
  resource_group_name = var.rg_Name

  security_rule {
    name                       = "Allow-Bastion-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.bastion_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Bastion-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-VNet-To-VNet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Internet-Outbound"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}
