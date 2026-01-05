
output "vm_id" {
  description = "The ID of the Virtual Machine"
  value = var.use_gallery_image ? azurerm_windows_virtual_machine.winvm_gallery[0].id : azurerm_windows_virtual_machine.winvm_marketplace[0].id
}

output "vm_ip_address" {
  description = "The Public IP Address of the Virtual Machine"
  value = var.use_gallery_image ? azurerm_windows_virtual_machine.winvm_gallery[0].public_ip_address : azurerm_windows_virtual_machine.winvm_marketplace[0].public_ip_address
}

output "vm_name" {
  description = "The Name of the Virtual Machine"
  value = var.use_gallery_image ? azurerm_windows_virtual_machine.winvm_gallery[0].name : azurerm_windows_virtual_machine.winvm_marketplace[0].name
}

output "vm_os_disk_id" {
  description = "The OS Disk ID of the Virtual Machine"
  value = var.use_gallery_image ? azurerm_windows_virtual_machine.winvm_gallery[0].os_disk[0].managed_disk_id : azurerm_windows_virtual_machine.winvm_marketplace[0].os_disk[0].managed_disk_id
}

output "vm_size" {
  description = "The Size of the Virtual Machine"
  value = var.use_gallery_image ? azurerm_windows_virtual_machine.winvm_gallery[0].size : azurerm_windows_virtual_machine.winvm_marketplace[0].size
}

output "vm_private_ip" {
  description = "The Private IP Address of the Virtual Machine"
  value = var.use_gallery_image ? azurerm_windows_virtual_machine.winvm_gallery[0].private_ip_address : azurerm_windows_virtual_machine.winvm_marketplace[0].private_ip_address
}