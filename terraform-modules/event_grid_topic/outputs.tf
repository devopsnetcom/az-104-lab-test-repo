output "eventgrid_topic_id" {
  value = data.azurerm_eventgrid_topic.existing_topic.id
}

output "eventgrid_topic_endpoint" {
  value = data.azurerm_eventgrid_topic.existing_topic.endpoint
}

output "eventgrid_topic_primary_key" {
  value = data.azurerm_eventgrid_topic.existing_topic.primary_access_key
}

