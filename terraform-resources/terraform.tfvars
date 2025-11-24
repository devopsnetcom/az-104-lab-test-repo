subscription_id = "8a430bad-846b-42a4-b674-138436f67a00"

# Keep only VM-specific configuration
pip_allocation     = "Static"
vm_nic             = "win_vm_nic"
ip_configuration   = "ip_config"

### Windows Virtual Machine Deployment
vm_name                     = "aicert-test-vm"
vm_size                     = "Standard_B2s"
vm_username                 = "AdminUser"
vm_password                 = "Admin@12356"
vm_image_publisher          = "MicrosoftWindowsServer"
vm_image_offer              = "WindowsServer"
vm_image_sku                = "2016-Datacenter"
vm_image_version            = "latest"
vm_os_disk_strg_type        = "Standard_LRS"
vm_os_disk_caching          = "ReadWrite"
vnet_Address                = "10.0.0.0/16"
subnet_AddressList          = ["10.0.1.0/24", "10.0.2.0/24"]
basinton_subnet_Address     = ["10.0.50.0/26"]
basiton_sku                 = "Standard"
basinton_ip_configuration   = "bastionConfig"
basiton_pip_sku             = "Standard"

## Event grid Topic details
eventgrid_topic_name = "egt-lab-eastus-001"
rg_corecomponent_name = "RG-CoreComponents"