
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

# Windows VM using either Marketplace image or Shared Image Gallery image (generalized)
resource "azurerm_windows_virtual_machine" "winvm_gallery" {
  name                = var.vm_name
  resource_group_name = var.rg_Name
  location            = var.location
  size                = var.vm_size

  # ALWAYS required for generalized images
  admin_username      = var.vm_username
  admin_password      = var.vm_password
  computer_name       = local.win_hostname

  network_interface_ids = [ azurerm_network_interface.vm_nic.id ]

  # Marketplace image (fallback)
  dynamic "source_image_reference" {
    for_each = var.use_gallery_image ? [] : [1]
    content {
      publisher = var.vm_image_publisher
      offer     = var.vm_image_offer
      sku       = var.vm_image_sku
      version   = var.vm_image_version
    }
  }

  # Shared Image Gallery (preferred)
  source_image_id = var.use_gallery_image ? var.image_defination_id : null

  # REQUIRED for Trusted Launch images
  #security_type         = "TrustedLaunch"
  secure_boot_enabled   = true
  vtpm_enabled          = true

  os_disk {
    storage_account_type = var.vm_os_disk_strg_type
    caching              = var.vm_os_disk_caching
  }
}



