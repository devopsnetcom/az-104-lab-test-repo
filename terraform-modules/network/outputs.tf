output "vnet_Name" {
  value = azurerm_virtual_network.student_vnet.name
}

output "vnet_Id" {
  value = azurerm_virtual_network.student_vnet.id
}

output "subnet_Id" {
  value = azurerm_subnet.student_subnet.*.id
}

# ✅ Added NSG ID output
output "nsg_id" {
  value = azurerm_network_security_group.vm_nsg.id
}