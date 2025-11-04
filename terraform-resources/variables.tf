## Subscription ID, Resource Group and Location set. These are kept universal in this code. ####
variable "subscription_id" { type = string }
variable "location" { type = string }
variable "rg_Name" { type = string }

### VNET Module Variables Start ###
variable "vnet_Name" { type = string }
variable "vnet_Address" { type = string }
variable "subnet_NameList" { type = list(string) }
variable "subnet_AddressList" { type = list(string) }

#### Variables for Windows Virtual Module defined here ####
variable "vm_pip" { type = string }
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