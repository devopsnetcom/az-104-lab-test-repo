/*
resource "azurerm_resource_group" "rg" {
  name     = var.rg_Name
  location = var.location
}*/

# ✅ DATA source to reference existing RG
data "azurerm_resource_group" "rg" {
  name = var.rg_Name
}

locals {
  prefix = lower(var.user_name)
}

############# VNET & SUBNET Deployment Code #############

module "vnet01" {
  source             = "../terraform-modules/network"
  vnet_Name          = "${local.prefix}-vnet"
  rg_Name            = data.azurerm_resource_group.rg.name
  location           = data.azurerm_resource_group.rg.location
  vnet_Address       = var.vnet_Address
  subnet_NameList    = var.subnet_NameList
  subnet_AddressList = var.subnet_AddressList
}

######### Azure Windows Virtual Machine deployment #########
module "winvm" {
  source               = "../terraform-modules/virtual_machine"
  vm_pip               = "${local.prefix}-pip"
  rg_Name              = data.azurerm_resource_group.rg.name
  location             = data.azurerm_resource_group.rg.location
  pip_allocation       = var.pip_allocation
  vm_nic               = "${local.prefix}-nic"
  ip_configuration     = "${local.prefix}-ip_configuration"
  vm_name              = "${local.prefix}-vm"
  vm_size              = var.vm_size
  vm_username          = var.vm_username
  vm_password          = var.vm_password
  vm_image_publisher   = var.vm_image_publisher
  vm_image_offer       = var.vm_image_offer
  vm_image_sku         = var.vm_image_sku
  vm_image_version     = var.vm_image_version
  vm_os_disk_strg_type = var.vm_os_disk_strg_type
  vm_os_disk_caching   = var.vm_os_disk_caching

  # ✅ Use last subnet dynamically
  vm_subnetid          = module.vnet01.subnet_Id[length(module.vnet01.subnet_Id) - 1]

  # ✅ Attach NSG to VM NIC
  nsg_id               = module.vnet01.nsg_id
}
