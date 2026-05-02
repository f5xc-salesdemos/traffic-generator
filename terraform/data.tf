data "azuread_client_config" "current" {}

data "azuread_user" "current" {
  count     = var.deployer == "" ? 1 : 0
  object_id = data.azuread_client_config.current.object_id
}
