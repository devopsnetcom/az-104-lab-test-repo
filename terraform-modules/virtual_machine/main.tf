
locals {
  win_hostname = substr(replace(var.vm_name, "-", ""), 0, 15)
}

resource "azurerm_network_interface" "vm_nic" {
  name                = var.vm_nic
  resource_group_name = var.rg_Name
  location            = var.location

  ip_configuration {
    name                          = var.ip_configuration
    subnet_id                     = var.vm_subnetid
    private_ip_address_allocation = "Dynamic"
  }
}

# ✅ Correct way to associate NSG to NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = var.nsg_id
}

# Deploy VM using Shared Image from Marketplace
resource "azurerm_windows_virtual_machine" "winvm_marketplace" {
  count = var.use_gallery_image ? 0 : 1

  name                = var.vm_name
  computer_name       = local.win_hostname
  resource_group_name = var.rg_Name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.vm_username
  admin_password      = var.vm_password

  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  os_disk {
    storage_account_type = var.vm_os_disk_strg_type
    caching              = var.vm_os_disk_caching
  }
}

# Deploy VM using Shared Image from Shared Image Gallery
resource "azurerm_windows_virtual_machine" "winvm_gallery" {
  count = var.use_gallery_image ? 1 : 0

  name                = var.vm_name
  resource_group_name = var.rg_Name
  location            = var.location
  size                = var.vm_size

  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  source_image_id = var.image_defination_id

  os_disk {
    storage_account_type = var.vm_os_disk_strg_type
    caching              = var.vm_os_disk_caching
  }
}


