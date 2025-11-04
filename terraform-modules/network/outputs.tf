output "vnet_Name" {
  value = azurerm_virtual_network.wec_vnet.name
}
output "vnet_Id" {
  value = azurerm_virtual_network.wec_vnet.id
}
output "subnet_Id" {
  value = azurerm_subnet.subnet.*.id
}