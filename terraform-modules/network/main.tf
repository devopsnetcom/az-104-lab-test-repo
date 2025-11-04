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

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.rg_Name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"  # Replace with your public IP for security
    destination_address_prefix = "*"
  }

  tags = {
    environment = "dev"
    application = "windows-vm"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_assoc" {
  subnet_id                 = azurerm_subnet.subnet[0].id
  network_security_group_id = azurerm_network_security_group.subnet_nsg.id
}
