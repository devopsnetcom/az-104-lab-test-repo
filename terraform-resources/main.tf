# Local variable to create resource names with user prefix
locals {
  prefix = lower(var.user_name)
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
  name                = var.shared_vnet_name
  resource_group_name = var.rg_corecomponent_name  
}

# Read existing guacamole subnet
data "azurerm_subnet" "guacamole_subnet" {
  name                 = var.guacamole_subnet_name
  virtual_network_name = data.azurerm_virtual_network.parent_vnet.name
  resource_group_name  = var.rg_corecomponent_name
}

############# VNET & SUBNET Deployment Code #############
module "vnet01" {
  source                  = "../terraform-modules/network"
  vnet_Name               = "${local.prefix}-vnet"
  user_name               = local.prefix
  rg_Name                 = data.azurerm_resource_group.rg.name
  rg_corecomponent_name   = var.rg_corecomponent_name
  location                = data.azurerm_resource_group.rg.location
  subnet_NameList         = var.subnet_NameList
  mother_vnet_name        = data.azurerm_virtual_network.parent_vnet.name
  mother_vnet_id          = data.azurerm_virtual_network.parent_vnet.id
  guacamole_subnet_cidr   = data.azurerm_subnet.guacamole_subnet.address_prefixes[0]
}

############## Shared VM Image Gallery Read ########################

# Replace placeholders in image definition offer name
locals {
  resolved_vm_image_definition_offer = replace(
    replace(
      var.vm_image_definition_offer,
      "{course}",
      var.course_name
    )
  )
}

# Read Shared Image Gallery
data "azurerm_shared_image_gallery" "gallery" {
  name                = var.compute_gallery_name
  resource_group_name = var.rg_corecomponent_name
}

# Read Shared Image Definition
data "azurerm_shared_image" "vm_image_def" {
  name                = local.resolved_vm_image_definition_offer
  gallery_name        = data.azurerm_shared_image_gallery.gallery.name
  resource_group_name = var.rg_corecomponent_name
}

# Local to decide whether to use Shared Image or Marketplace image
locals {
  use_gallery_image = (
    try(data.azurerm_shared_image.vm_image_def.id, null) != null
  )
}


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

  # Image selection logic
  use_gallery_image    = local.use_gallery_image
  image_defination_id  = local.use_gallery_image ? data.azurerm_shared_image.vm_image_def.id : ""

  vm_image_publisher   = local.use_gallery_image ? null : var.vm_image_default_publisher
  vm_image_offer       = local.use_gallery_image ? null : var.vm_image_default_offer
  vm_image_sku         = local.use_gallery_image ? null : var.vm_image_default_sku

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
  tenant_id               = var.tenant_id
  user_name               = local.prefix
  course_name             = var.course_name
  module_name             = var.module_name
  vm_name                 = module.winvm.vm_name
  vm_username             = var.vm_username
  vm_password             = var.vm_password
  vm_id                   = module.winvm.vm_id
  vm_private_ip           = module.winvm.vm_private_ip
  user_identifier         = var.user_identifier
}

/* Debug Outputs
output "use_gallery_image" {
  value = local.use_gallery_image
}

output "image_defination_id" {
  value = data.azurerm_shared_image.vm_image_def.id
}*/
