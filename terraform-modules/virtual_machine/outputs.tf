
output "vm_id" {
  description = "The ID of the Virtual Machine"
  value = azurerm_windows_virtual_machine.winvm_gallery.id
}

output "vm_ip_address" {
  description = "The Public IP Address of the Virtual Machine"
  value = azurerm_windows_virtual_machine.winvm_gallery.public_ip_address
}

output "vm_name" {
  description = "The Name of the Virtual Machine"
  value = azurerm_windows_virtual_machine.winvm_gallery.name
}

output "vm_os_disk_id" {
  description = "The OS Disk ID of the Virtual Machine"
  value = azurerm_windows_virtual_machine.winvm_gallery.os_disk[0].managed_disk_id
}

output "vm_size" {
  description = "The Size of the Virtual Machine"
  value = azurerm_windows_virtual_machine.winvm_gallery.size
}

output "vm_private_ip" {
  description = "The Private IP Address of the Virtual Machine"
  value = azurerm_windows_virtual_machine.winvm_gallery.private_ip_address
}