
output "vm_id" {
  description = "The ID of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.winvm.id
}

output "vm_ip_address" {
  description = "The Public IP Address of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.winvm.public_ip_address
}

output "vm_name" {
  description = "The Name of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.winvm.name
}

output "vm_os_disk_id" {
  description = "The OS Disk ID of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.winvm.os_disk[0].id
}

output "vm_size" {
  description = "The Size of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.winvm.size
}