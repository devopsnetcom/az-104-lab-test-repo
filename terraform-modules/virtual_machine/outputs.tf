
output "vm_id" {
  description = "The ID of the Virtual Machine"
  value       = azurerm_virtual_machine.main.id
}

output "vm_ip_address" {
  description = "The Public IP Address of the Virtual Machine"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_name" {
  description = "The Name of the Virtual Machine"
  value       = azurerm_virtual_machine.main.name
}
