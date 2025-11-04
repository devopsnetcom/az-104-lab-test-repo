resource "azurerm_resource_group" "rg" {
  name     = var.rg_Name
  location = var.location
}

############# VNET & SUBNET Deployment Code #############

module "vnet01" {
  source             = "../terraform-modules/network"
  vnet_Name          = var.vnet_Name
  rg_Name            = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  vnet_Address       = var.vnet_Address
  subnet_NameList    = var.subnet_NameList
  subnet_AddressList = var.subnet_AddressList
}

######### Azure Windows Virtual Machine deployment #########
module "winvm" {
  source               = "../terraform-modules/virtual_machine"
  vm_pip               = var.vm_pip
  rg_Name              = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  pip_allocation       = var.pip_allocation
  vm_nic               = var.vm_nic
  ip_configuration     = var.ip_configuration
  vm_name              = var.vm_name
  vm_size              = var.vm_size
  vm_username          = var.vm_username
  vm_password          = var.vm_password
  vm_image_publisher   = var.vm_image_publisher
  vm_image_offer       = var.vm_image_offer
  vm_image_sku         = var.vm_image_sku
  vm_image_version     = var.vm_image_version
  vm_os_disk_strg_type = var.vm_os_disk_strg_type
  vm_os_disk_caching   = var.vm_os_disk_caching

  # ✅ Fix: use last subnet dynamically
  vm_subnetid          = module.vnet01.subnet_Id[length(module.vnet01.subnet_Id) - 1]
}