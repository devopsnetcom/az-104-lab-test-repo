subscription_id = "8a430bad-846b-42a4-b674-138436f67a00"

# Keep only VM-specific configuration
pip_allocation     = "Static"
vm_nic             = "win_vm_nic"
ip_configuration   = "ip_config"

### Windows Virtual Machine Deployment
vm_size                             = "Standard_B2s" 
vm_username                         = "AdminUser"
vm_password                         = "Admin@12356"
vm_image_default_publisher          = "MicrosoftWindowsServer"
vm_image_default_offer              = "WindowsServer" 
vm_image_default_sku                = "2016-Datacenter"
vm_image_version                    = "latest"
vm_os_disk_strg_type                = "Standard_LRS"
vm_os_disk_caching                  = "ReadWrite"
subnet_NameList                     = ["subnet-1", "subnet-2"]

## Event grid Topic details
eventgrid_topic_name = "egt-lab365-eastus-001"
rg_corecomponent_name = "RG-CoreComponents"
course_name = "AZ-104"
module_name = "Lab01"

#guacamole network details
shared_vnet_name            = "Shared-Hub-VNet"
guacamole_subnet_name       = "guac-subnet"

#VM Image Gallery Name & defination name
compute_gallery_name            = "goldenimagepocacg"
vm_image_definition_publisher   = "MicrosoftWindowsServer"
vm_image_definition_offer       = "az-104_lab-01-winserdc2025g2" ## {course}-{module}-winserdc2025g2
vm_image_definition_sku         = "2025-datacenter-g2"