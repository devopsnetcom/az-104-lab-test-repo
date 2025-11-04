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

# -------------------------------
# Network Security Group (NSG)
# -------------------------------
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vnet_Name}-nsg"
  location            = var.location
  resource_group_name = var.rg_Name

  security_rule {
    name                       = "RDP"
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
    name                       = "Allow-Internet-Outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
