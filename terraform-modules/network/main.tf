resource "azurerm_virtual_network" "wec_vnet" {
  name                = var.vnet_Name
  resource_group_name = var.rg_Name
  location            = var.location
  address_space       = [var.vnet_Address]
}

resource "azurerm_subnet" "subnet" {
  count                = length(var.subnet_NameList)
  name                 = var.subnet_NameList[count.index]
  virtual_network_name = azurerm_virtual_network.wec_vnet.name
  resource_group_name  = var.rg_Name
  address_prefixes     = [var.subnet_AddressList[count.index]]
}

/* Both way Vnet Peering between Mother VNet and Student VNet */
resource "azurerm_virtual_network_peering" "student_to_mother" {
  name                      = "peer-student-to-mother"
  resource_group_name       = var.rg_Name
  virtual_network_name      = azurerm_virtual_network.wec_vnet.name
  remote_virtual_network_id = var.mother_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "mother_to_student" {
  name                      = "peer-mother-to-student"
  resource_group_name       = var.rg_Name
  virtual_network_name      = var.mother_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.wec_vnet.id
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
    source_address_prefix      = "*"
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
    source_address_prefix      = "AzureBastion"
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
