resource "azurerm_resource_group" "main" {
  name     = local.name.resource_group
  location = var.location
  tags     = local.tags
}
