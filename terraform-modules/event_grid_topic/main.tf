
resource "random_uuid" "event" {}

data "azurerm_eventgrid_topic" "existing_topic" {
  name                = var.eventgrid_topic_name
  resource_group_name = var.rg_corecomponent_name
}

resource "azurerm_role_assignment" "eventgrid_sender" {
  scope                = data.azurerm_eventgrid_topic.existing_topic.id
  role_definition_name = "EventGrid Data Contributor"
  principal_id         = var.principal_id
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
      $payload = @(
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
      ) | ConvertTo-Json -Depth 10

      az eventgrid event publish `
        --topic-endpoint ${data.azurerm_eventgrid_topic.existing_topic.endpoint} `
        --event-data "$payload"
      EOT
    }
}




