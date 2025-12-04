
locals {
  target_role_name = "EventGrid Data Contributor"
}

resource "random_uuid" "event" {}

data "azurerm_eventgrid_topic" "existing_topic" {
  name                = var.eventgrid_topic_name
  resource_group_name = var.rg_corecomponent_name
}

# Use a data source to get the GUID of the specific role name
data "azurerm_role_definition" "eventgrid_contributor" {
  name  = local.target_role_name
  scope = data.azurerm_eventgrid_topic.existing_topic.id
}

# Clean the principal_id to a normalized format (lowercase, GUID-only)
locals {
  cleaned_principal_id = lower(replace(replace(lower(coalesce(var.principal_id, "")),"/serviceprincipals/",""),"/",""))
}

# Data block to check if the Role Assignment exists
data "azurerm_role_assignments" "existing_sender_list" {
  scope                = data.azurerm_eventgrid_topic.existing_topic.id
  #principal_id         = local.cleaned_principal_id
}

# Logic to determine if Role Assignment needs to be created
locals {

  # Normalized view of existing assignments (lowercase, GUID-only principal)
  normalized_assignments = [
    for ra in data.azurerm_role_assignments.existing_sender_list.role_assignments : {
      principal_id_norm = lower(replace(replace(lower(coalesce(ra.principal_id, "")),"/serviceprincipals/",""),"/",""))

      role_def_id_norm = lower(coalesce(ra.role_definition_id, ""))
    }
  ]

  target_role_def_id_norm = lower(data.azurerm_role_definition.eventgrid_contributor.id)

  # find matching assignment(s) for our SPN + role
  matching_assignments = [
    for na in local.normalized_assignments : na
    if na.principal_id_norm == local.cleaned_principal_id && na.role_def_id_norm == local.target_role_def_id_norm
  ]

  should_create_assignment = length(local.matching_assignments) == 0
}

# check if role assignment exists
locals {
  role_exists = length(local.matching_assignments) > 0
}

locals {
  assignment_enabled = local.role_exists ? {
      "eventgrid_sender" = {
        principal_id  = local.cleaned_principal_id
        role_def_name = local.target_role_name
      }
    } : local.should_create_assignment ? {
      "eventgrid_sender" = {
        principal_id  = local.cleaned_principal_id
        role_def_name = local.target_role_name
      }
    } : {}
}

# Create the Role Assignment only if it does NOT exist
resource "azurerm_role_assignment" "eventgrid_sender" {
  for_each = local.assignment_enabled

  scope                = data.azurerm_eventgrid_topic.existing_topic.id
  role_definition_name = each.value.role_def_name
  principal_id         = each.value.principal_id

}

################################################################

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
                    userIdentifier          = "${var.user_identifier}"
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




