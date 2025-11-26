
data "azurerm_eventgrid_topic" "existing_topic" {
  name                = var.eventgrid_topic_name
  resource_group_name = var.rg_corecomponent_name
}

locals {
  # Clean up the principal ID input (e.g. removing graph API URLs)
  cleaned_principal_id = replace(replace(var.principal_id, "/servicePrincipals/", ""), "/","")
  
  target_role_name     = "EventGrid Data Contributor"
}

# Data block to check if the Role Assignment exists
data "azurerm_role_assignments" "existing_sender_list" {
  scope                = data.azurerm_eventgrid_topic.existing_topic.id
  principal_id         = local.cleaned_principal_id
}

locals {
  # Filter the list of assignments returned by the data source
  matching_assignments = [
    for ra in data.azurerm_role_assignments.existing_sender_list.role_assignments : ra.id

    # Check if the principal_id matches AND the role_definition_name matches
    if ra.principal_id == local.cleaned_principal_id && ra.role_definition_name == local.target_role_name
  ]

  # Determine if we need to create the resource (length is 0 if no match was found)
  should_create_assignment = length(local.matching_assignments) == 0
}

# Create the Role Assignment only if it does NOT exist
resource "azurerm_role_assignment" "eventgrid_sender" {
  # Count will be 1 if should_create_assignment is true, otherwise 0 (skipped)
  count = local.should_create_assignment ? 1 : 0

  scope                = data.azurerm_eventgrid_topic.existing_topic.id
  role_definition_name = local.target_role_name
  principal_id         = local.cleaned_principal_id
}



resource "null_resource" "send_vm_event" {
  depends_on = [
    azurerm_role_assignment.eventgrid_sender
  ]

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
                    courseName              = "${var.course_name}"
                    moduleName              = "${var.module_name}"
                    vmName                  = "${var.vm_name}"
                    vmUsername              = "${var.vm_username}"
                    vmPassword              = "${var.vm_password}" 
                    vmResourceId            = "${var.vm_id}"
                    vmConnectURL            = "https://portal.azure.com/#@${var.tenant_id}/resource${var.vm_id}/bastionHost"
                    bastionHostResourceId   = "${var.bastion_id}"
                    bastionUrl              = "https://portal.azure.com/#resource${var.bastion_id}"                  
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




