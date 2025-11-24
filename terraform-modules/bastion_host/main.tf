
resource "azurerm_public_ip" "bastion_pip" {
  name                = var.bastion_pip_name
  resource_group_name = var.rg_Name
  location            = var.location
  allocation_method   = var.pip_allocation
  sku                 = var.basiton_pip_sku
}

resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_Name
  resource_group_name = var.rg_Name
  location            = var.location
  sku                 = var.basiton_sku

  ip_configuration {
    name                 = var.basinton_ip_configuration
    subnet_id            = var.basinton_subnet_Id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}