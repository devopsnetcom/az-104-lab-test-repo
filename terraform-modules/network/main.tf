###########################################
# Get ALL VNETs from RG
###########################################
data "azurerm_resources" "all_vnets" {
  type                = "Microsoft.Network/virtualNetworks"
}

###########################################
# Extract only student VNET names (exclude mother)
########################################
locals {
  student_vnets = {
    for v in data.azurerm_resources.all_vnets.resources :
    "${v.resource_group_name}/${v.name}" => {
      vnet_name = v.name
      rg_name   = v.resource_group_name
    }
    if lower(v.name) != lower(var.mother_vnet_name)
  }
}

###########################################
# Fetch each student VNET
###########################################
data "azurerm_virtual_network" "student_vnets" {
  for_each = local.student_vnets

  name                = each.value.vnet_name
  resource_group_name = each.value.rg_name
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
# Check if CURRENT student's VNET already exists
###########################################
locals {
  current_vnet_key = "${var.rg_Name}/${var.vnet_Name}"

  current_vnet_exists = contains(keys(local.student_vnets),local.current_vnet_key)
}

###########################################
# Get EXISTING CIDR for CURRENT user (if exists)
###########################################
locals {
  current_vnet_existing_cidr = (
    local.current_vnet_exists ? data.azurerm_virtual_network.student_vnets[local.current_vnet_key].address_space[0] : null
  )
}

###########################################
# Extract used second octets (10.X.0.0/16)
###########################################
locals {
  used_octets = length(local.student_vnet_cidrs) > 0 ? [
    for cidr in local.student_vnet_cidrs :
    tonumber(regex("^10\\.(\\d+)\\.", cidr)[0])
    if can(regex("^10\\.(\\d+)\\.", cidr))
  ] : []
}

###########################################
# Calculate next available octet (only for NEW vnets)
###########################################
locals {
  possible_octets = range(1, 255)

  free_octets = [
    for o in local.possible_octets :
    o if !contains(local.used_octets, o)
  ]

  next_octet = local.free_octets[0]
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

resource "azurerm_virtual_network_peering" "mother_to_student" {
  name                      = "peer-mother-to-${var.user_name}"
  resource_group_name       = var.rg_corecomponent_name
  virtual_network_name      = var.mother_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.student_vnet.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "student_to_mother" {
  name                      = "peer-${var.user_name}-to-mother"
  resource_group_name       = var.rg_Name
  virtual_network_name      = azurerm_virtual_network.student_vnet.name
  remote_virtual_network_id = var.mother_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false

  depends_on = [ 
    azurerm_virtual_network_peering.mother_to_student 
  ]
}


# -------------------------------
# Network Security Group (NSG)
# -------------------------------
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vnet_Name}-nsg"
  location            = var.location
  resource_group_name = var.rg_Name

  security_rule {
    name                       = "Allow-Guac-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.guacamole_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Guac-RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.guacamole_subnet_cidr
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
