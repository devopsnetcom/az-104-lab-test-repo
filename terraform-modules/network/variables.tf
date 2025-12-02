variable "location" { type = string }
variable "rg_Name" { type = string }
variable "vnet_Name" { type = string }
variable "subnet_NameList" { type = list(string) }
variable "mother_vnet_name" { type = string }
variable "mother_vnet_id" { type = string }
variable "bastion_subnet_cidr" { type = string }
variable "user_name" { type = string }