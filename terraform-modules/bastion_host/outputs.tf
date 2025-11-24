output "bastion_host_name" {
  description = "The name of the Bastion Host"
  value       = azurerm_bastion_host.bastion.name  
}

output "bastion_public_ip" {
  description = "The Public IP address of the Bastion Host"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

output "bastion_host_id" {
  description = "The ID of the Bastion Host"
  value       = azurerm_bastion_host.bastion.id  
}

