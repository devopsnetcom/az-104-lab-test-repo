
locals {
  prefix = lower(var.user_name)
}

locals {
  mother_vnet_name = "${var.course_name}-${var.module_name}-vnet"
  bastion_name = "${var.course_name}-${var.module_name}-vnet-bastion"
}

# ✅ DATA source to reference existing RG
data "azurerm_resource_group" "rg" {
  name = var.rg_Name
}

data "azuread_service_principal" "github_spn" {
  client_id = var.github_spn_client_id
}

# Read specific Mother VNET
data "azurerm_virtual_network" "parent_vnet" {
  name                = local.mother_vnet_name
  resource_group_name = var.rg_Name  
}

# Read specific Bastion subnet
data "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = data.azurerm_virtual_network.parent_vnet.name
  resource_group_name  = var.rg_Name
}

# Get the Bastion Host
data "azurerm_bastion_host" "bastion_host" {
  name                = local.bastion_name
  resource_group_name = var.rg_Name
}


############# VNET & SUBNET & Basinton Subnet Deployment Code #############
module "vnet01" {
  source                  = "../terraform-modules/network"
  vnet_Name               = "${local.prefix}-vnet"
  user_name               = local.prefix
  rg_Name                 = data.azurerm_resource_group.rg.name
  location                = data.azurerm_resource_group.rg.location
  subnet_NameList         = var.subnet_NameList
  mother_vnet_name        = data.azurerm_virtual_network.parent_vnet.name
  mother_vnet_id          = data.azurerm_virtual_network.parent_vnet.id
  bastion_subnet_cidr     = data.azurerm_subnet.bastion.address_prefix
}

#### Azure Bastion Host Deployment ####
/*
module "bastionhost" {
  source                    = "../terraform-modules/bastion_host"
  bastion_pip_name          = "${local.prefix}-vnet-bastion-IPv4"
  bastion_Name              = "${local.prefix}-vnet-bastion"
  rg_Name                   = data.azurerm_resource_group.rg.name
  location                  = data.azurerm_resource_group.rg.location
  pip_allocation            = var.pip_allocation
  basiton_sku               = var.basiton_sku
  basinton_subnet_Id        = module.vnet01.basinton_subnet_Id
  basinton_ip_configuration = var.basinton_ip_configuration
  basiton_pip_sku           = var.basiton_pip_sku
}*/

######### Azure Windows Virtual Machine deployment #########
module "winvm" {
  source               = "../terraform-modules/virtual_machine"
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

#### Event Grid Topic Module Deployment ####
module "eventgrid_topic" {
  source                  = "../terraform-modules/event_grid_topic"
  eventgrid_topic_name    = var.eventgrid_topic_name
  rg_corecomponent_name   = var.rg_corecomponent_name
  principal_id            = data.azuread_service_principal.github_spn.id
  tenant_id               = var.tenant_id
  user_name               = local.prefix
  course_name             = var.course_name
  module_name             = var.module_name
  vm_name                 = module.winvm.vm_name
  vm_username             = var.vm_username
  vm_password             = var.vm_password
  vm_id                   = module.winvm.vm_id
  bastion_name            = local.bastion_name
  bastion_id              = data.azurerm_bastion_host.bastion_host.id
  user_identifier         = var.user_identifier
}

/* Debug Outputs
output "principal_id_debug" {
  value = data.azuread_service_principal.github_spn.id
} */



