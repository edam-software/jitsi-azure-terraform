resource "random_string" "db_user" {
  length  = 12
  special = false
  upper   = true
  number  = true

}

resource "random_string" "db_password" {
  length  = 28
  special = false
  upper = true
  number = true

  keepers = {
    cluster_identifier = random_string.db_user.result
  }
}

/*

$$ install local postgres $$

resource "azurerm_postgresql_server" "postgresql" {
    depends_on = [local.db_username, local.db_password]
    name                         = "${var.prefix}-postgres-server"
    resource_group_name          = azurerm_resource_group.main.name
    location                     = azurerm_resource_group.main.location
    version                      = "11"
    administrator_login          = local.db_username
    administrator_login_password = local.db_password
    sku_name = "B_Gen5_1"
    storage_mb = 5120
    public_network_access_enabled = true
    ssl_enforcement_enabled = true
    ssl_minimal_tls_version_enforced = "TLS1_2"

  lifecycle { ignore_changes = [administrator_login_password]}
}

resource "azurerm_postgresql_database" "postgres" {
  depends_on = [azurerm_postgresql_server.postgresql]
  name                             = local.db_name
  resource_group_name              = azurerm_resource_group.main.name
  server_name                      = azurerm_postgresql_server.postgresql.name
  charset             = "UTF8"
  collation           = "English_United States.1252"

}

# create a temp manual rule for image VM on private subnet
# psql: error: FATAL:  no pg_hba.conf entry for host "XYZ.NN.PP.QQ"

# production prosody
resource "azurerm_postgresql_firewall_rule" "postgres" {
  name                = "${var.prefix}-backend"
  resource_group_name          = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.postgresql.name
  start_ip_address    = azurerm_public_ip.web.ip_address
  end_ip_address      = azurerm_public_ip.web.ip_address
}

*/