
resource "random_uuid" "event" {}

data "azurerm_eventgrid_topic" "existing_topic" {
  name                = var.eventgrid_topic_name
  resource_group_name = var.rg_corecomponent_name
}

resource "azurerm_role_assignment" "eventgrid_sender" {
  scope                = data.azurerm_eventgrid_topic.existing_topic.id
  role_definition_name = "EventGrid Data Contributor"
  principal_id         = replace(replace(var.principal_id, "/servicePrincipals/", ""), "/","")
}


resource "null_resource" "send_vm_event" {
  depends_on = [
    azurerm_role_assignment.eventgrid_sender
  ]

  triggers = {
    bastion_name = var.bastion_name
  }

  provisioner "local-exec" {
      interpreter = ["pwsh", "-Command"]

      command = <<EOT
      # Build JSON array payload using PowerShell
      $event = @(
          @{
              id          = "vm-${var.vm_name}-event-${random_uuid.event.result}"
              eventType   = "VM.Created"
              subject     = "terraform/vm/${var.vm_name}"
              eventTime   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
              data        = @{
                  userName                = "${var.user_name}"
                  courseName              = "${var.course_name}"
                  moduleName              = "${var.module_name}"
                  vmName                  = "${var.vm_name}"
                  vmUsername              = "${var.vm_username}"
                  vmPassword              = "${var.vm_password}" 
                  vmResourceId            = "${var.vm_id}"
                  vmConnectURL            = "https://portal.azure.com/#@${var.tenant_id}/resource${var.vm_id}/bastionHost"                  
                  vmip                    = "${var.vm_ip}"
                  bastionHostResourceId   = "${var.bastion_id}"
                  bastionUrl              = "https://portal.azure.com/#resource${var.bastion_id}"                  
                  status                  = "Ready"
              }
              dataVersion = "1.0"
          }
      )

      # Event Grid requires an ARRAY
      $payload = @($event) | ConvertTo-Json -Depth 10

      $payload | Write-Host

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




