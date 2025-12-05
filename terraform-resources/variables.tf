## Subscription ID, Resource Group and Location set. These are kept universal in this code. ####
variable "subscription_id" { type = string }
variable "location" { type = string }
variable "rg_Name" { type = string }
variable "user_name" { type = string }
variable "tenant_id" { type = string }
variable "github_spn_client_id" { type = string }
variable "user_identifier" { type = string }

### VNET Module Variables Start ###
variable "subnet_NameList" { type = list(string) }
/*
variable "basinton_subnet_Address" { type = list(string) }
variable "basiton_sku" { type = string }
variable "basinton_ip_configuration" { type = string }
variable "basiton_pip_sku" { type = string }
*/

#### Variables for Windows Virtual Module defined here ####
variable "pip_allocation" { type = string }
variable "vm_nic" { type = string }
variable "ip_configuration" { type = string }
variable "vm_name" { type = string }
variable "vm_size" { type = string }
variable "vm_username" { type = string }
variable "vm_password" { type = string }
variable "vm_image_publisher" { type = string }
variable "vm_image_offer" { type = string }
variable "vm_image_sku" { type = string }
variable "vm_image_version" { type = string }
variable "vm_os_disk_strg_type" { type = string }
variable "vm_os_disk_caching" { type = string }

### Event Grid Topic Module Variables ###
variable "eventgrid_topic_name" { type = string }
variable "rg_corecomponent_name" { type = string }
variable "course_name" { type = string }
variable "module_name" { type = string }