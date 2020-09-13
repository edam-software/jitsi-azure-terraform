resource "azurerm_key_vault" "main" {
  name                = "${var.prefix}-vault"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"
  enabled_for_deployment = true
  enabled_for_template_deployment = true
  #
  #access_policy = []
}

# for terraform refresh
resource "azurerm_key_vault_access_policy" "create" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.client_id
  secret_permissions = var.kv_secret_permissions_full
  key_permissions = var.kv_key_permissions_full
  storage_permissions = var.kv_storage_permissions_full
  certificate_permissions = var.kv_certificate_permissions_full
}

resource "azurerm_key_vault_access_policy" "run" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_user_assigned_identity.main.principal_id
  secret_permissions = var.kv_secret_permissions_full
  key_permissions = var.kv_key_permissions_full
  storage_permissions = var.kv_storage_permissions_full
  certificate_permissions = var.kv_certificate_permissions_full
}

//resource "azurerm_key_vault_secret" "test" {
//  name         = "test"
//  value        = ""
//  key_vault_id = azurerm_key_vault.main.id
//}