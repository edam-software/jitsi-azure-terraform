# temp VM for image

/*
resource azurerm_linux_virtual_machine "image_vm" {
  name = "${var.prefix}-image"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  admin_username = var.ssh_username
  allow_extension_operations = true
  size = var.imagevm_sku


  depends_on = [azurerm_network_interface.image_vm]

  network_interface_ids = [
    azurerm_network_interface.image_vm.id]

  admin_ssh_key {
    username = var.ssh_username
    public_key = local.pub_key
  }

  source_image_reference {
    publisher = var.publisher
    offer = var.offer
    sku = var.sku
    version = var.image_version
  }

  os_disk {
    storage_account_type = var.disk
    caching = "ReadWrite"
  }
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

}
*/
/*

resource "azurerm_virtual_machine_extension" "jitsi_install" {
  name = "${var.prefix}-jitsi-install"
  virtual_machine_id = azurerm_linux_virtual_machine.image_vm.id
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
      "script" = base64encode(templatefile("${path.module}/templates/image.tpl",
                                            {
                                              hostname= "${var.web_host}.${var.domain}"
                                              email = var.cert_email
                                              lang = var.default_language
                                              cert_name = local.cert_name
                                              vault_name = azurerm_key_vault.main.name
                                              db_name = local.db_name
                                              db_user = local.db_username
                                              db_password = local.db_password
                                              db_host = "localhost" #azurerm_postgresql_server.postgresql.fqdn
                                              low_bitrate = var.video_quality.low_bitrate
                                              med_bitrate = var.video_quality.med_bitrate
                                              high_bitrate = var.video_quality.high_bitrate
                                              resolution = var.video_quality.resolution
                                              lastN = var.video_quality.lastN
                                              layer_suspension = var.video_quality.layer_suspension
                                            }))
    })

}
*/
