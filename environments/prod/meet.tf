# Jitsi Meet Azure Image and Scale Set
# edamsoft 2021

//resource "local_file" "inventory" {
//    content     = "foo!"
//    filename = "${path.module}/ansible/inventory.yml"
//}

locals {
  db_username = random_string.db_user.result
  db_password = random_string.db_password.result
  db_name = "${var.prefix}_jitsi"
  ssh_key = var.ssh_file == null ? "" : var.ssh_file
  pub_key = local.ssh_key != "" ? local.ssh_key : tls_private_key.jitsi.public_key_openssh
  tags = { name = "jitsi-meet", location = var.location }
  cert_name = "${var.prefix}-le-cert"
  vmss_image = replace(var.vmss_image_resource_id, "ACCOUNT_NO", data.azurerm_client_config.current.subscription_id)
}

resource "azurerm_user_assigned_identity" "main" {
  name = "${var.prefix}-sys"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location

}

resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name = "${var.prefix}-scaler"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  depends_on = [local.pub_key,
                data.azurerm_public_ip.web,
                azurerm_key_vault_access_policy.run,
                azurerm_lb_probe.probe,
                azurerm_lb.main]
  sku = var.vmss_sku
  priority = "Spot"
  eviction_policy = "Delete"
  # The evicted VMs are deleted together with their underlying disks,
  # and therefore you will not be charged for the storage.
  # You can also use the auto-scaling feature of scale sets to automatically
  # try and compensate for evicted VMs, however, there is no guarantee that the allocation will succeed.
  source_image_id = local.vmss_image
  /* 1st runs use ubuntu std
     to get lets encrypt with VIP
     the we use source_image_id

    source_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "20.04-LTS"
      version   = "latest"
    }
  */

  instances = var.vmss_count
  single_placement_group = true
  overprovision = false
  # do_not_run_extensions_on_overprovisioned_machines = true
  zones = ["1", "2", "3"]
  tags = local.tags
  admin_username = var.ssh_username
  disable_password_authentication = true
  health_probe_id = azurerm_lb_probe.probe.id
  upgrade_mode = "Automatic"

  automatic_os_upgrade_policy {
    disable_automatic_rollback = true
    enable_automatic_os_upgrade = true
  }

  automatic_instance_repair {
    enabled = true
    grace_period = "PT10M"
    # It must be formatted as an ISO 8601 non-negative time span
    # and should have a minimum value of 10 minutes
    # and a maximum value of 90 minutes

  }
  # Todo:
  /* should use vault key instead of tarball
  secret {
  }
  */

  rolling_upgrade_policy {
    # null forces replacement
    max_batch_instance_percent = 20 #-> null forces replacement
    max_unhealthy_instance_percent = 20
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches = "PT0S" #-> null forces replacement
  }
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

//  lifecycle {
//    ignore_changes = [instances]
//  }

  admin_ssh_key {
    public_key = local.pub_key
    username = var.ssh_username
  }

  network_interface {
    name = "${var.prefix}-vmss-nic"
    primary = true
    network_security_group_id = azurerm_network_security_group.main.id

    ip_configuration {
      name = "${var.prefix}-vmss-vip"
      primary = true
      subnet_id = azurerm_subnet.internal.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.main.id]
    }
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching = "ReadWrite"
  }

  # https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux
  extension {
    name = "${var.prefix}-jitsi_user_setup"
    publisher = "Microsoft.Azure.Extensions"
    type = "CustomScript"
    type_handler_version = "2.1"

    settings = jsonencode({
      "script" = base64encode(templatefile("${path.module}/templates/setup.tpl",
                                            {
                                              hostname= "${var.web_host}.${var.domain}"
                                              email = var.cert_email
                                              vip = data.azurerm_public_ip.web.ip_address
                                              user_login = var.jitsi_user
                                              user_password = var.jitsi_password
                                              low_bitrate = var.video_quality.low_bitrate
                                              med_bitrate = var.video_quality.med_bitrate
                                              high_bitrate = var.video_quality.high_bitrate
                                              lastN = var.video_quality.lastN
                                              layer_suspension = var.video_quality.layer_suspension
                                            }))
    })
  }
}

resource "tls_private_key" "jitsi" {
  algorithm = "RSA"
  rsa_bits = 4096
}


resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "${var.prefix}-autoscale-setting"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.vmss_count
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
        #metric_namespace   = "microsoft.compute/virtualmachinescalesets"

      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = [var.cert_email]
    }
  }
}