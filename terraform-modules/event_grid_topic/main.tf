
# Retrieve existing Event Grid Topic
data "azurerm_eventgrid_topic" "existing_topic" {
  name                = var.eventgrid_topic_name
  resource_group_name = var.rg_corecomponent_name
}

# Send VM Created Event to Event Grid Topic
resource "null_resource" "send_vm_event" {
  
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
      interpreter = ["pwsh", "-Command"]

      command = <<EOT
      #Construct body using Hashtable
      $event = @{
                id          = "vm-${var.vm_name}-event-${uuid()}"
                eventType   = "VM.Created"
                subject     = "terraform/vm/${var.vm_name}"
                eventTime   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                data        = @{
                    userName                = "${var.user_name}"
                    userIdentifier          = "${var.user_identifier}"
                    courseName              = "${var.course_name}"
                    moduleName              = "${var.module_name}"
                    vmName                  = "${var.vm_name}"
                    vmUsername              = "${var.vm_username}"
                    vmPassword              = "${var.vm_password}" 
                    vmResourceId            = "${var.vm_id}"
                    vmPrivateIP             = "${var.vm_private_ip}"                 
                    status                  = "Ready"
                }
                dataVersion = "1.0"
          }

      # Event Grid requires an ARRAY of events even for a single event
      $payload = "["+(ConvertTo-Json $event)+"]"

      # Retrieve Topic Key
      $key = az eventgrid topic key list `
            --name ${data.azurerm_eventgrid_topic.existing_topic.name} `
            --resource-group ${data.azurerm_eventgrid_topic.existing_topic.resource_group_name} `
            --query "key1" -o tsv
      
      
      # Send Event using REST API (works on any CLI version)
      Invoke-RestMethod `
          -Uri "${data.azurerm_eventgrid_topic.existing_topic.endpoint}" `
          -Method POST `
          -Headers @{ "aeg-sas-key" = $key } `
          -Body $payload `
          -ContentType "application/json"

      EOT
    }
}




