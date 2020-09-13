# Load Balance

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  depends_on = [azurerm_public_ip.web]
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku = "Standard"

  frontend_ip_configuration {
    name                 = "${var.prefix}-vip"
    public_ip_address_id = azurerm_public_ip.web.id

  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name                = "${var.prefix}-web"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
}

# LoadBalancingRuleMustDisableSNATSinceSameFrontendIPConfigurationIsReferencedByOutboundRule
//resource "azurerm_lb_outbound_rule" "main" {
//  name                    = "OutboundRule"
//  resource_group_name     = azurerm_resource_group.main.name
//  loadbalancer_id         = azurerm_lb.main.id
//  protocol                = "Tcp"
//  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
//
//  frontend_ip_configuration {
//    name = "${var.prefix}-vip"
//  }
//}

resource "azurerm_lb_probe" "probe" {
  loadbalancer_id = azurerm_lb.main.id
  name = "${var.prefix}-meet-probe"
  port = 443
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_lb_rule" "web" {
  name = "${var.prefix}-web"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.main.id
  protocol = "Tcp"
  frontend_ip_configuration_name = "${var.prefix}-vip"
  frontend_port = 80
  backend_port = 80
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  probe_id = azurerm_lb_probe.probe.id

}

resource "azurerm_lb_rule" "ssl" {
  name = "${var.prefix}-ssl"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.main.id
  protocol = "Tcp"
  frontend_ip_configuration_name = "${var.prefix}-vip"
  frontend_port = 443
  backend_port = 443
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  probe_id = azurerm_lb_probe.probe.id
}

resource "azurerm_lb_rule" "media" {
  name = "${var.prefix}-tcp-media"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.main.id
  protocol = "Tcp"
  frontend_ip_configuration_name = "${var.prefix}-vip"
  frontend_port = 4443
  backend_port = 4443
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  probe_id = azurerm_lb_probe.probe.id
}

resource "azurerm_lb_rule" "media-udp" {
  name = "${var.prefix}-udp-media"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.main.id
  protocol = "Udp"
  frontend_ip_configuration_name = "${var.prefix}-vip"
  frontend_port = 10000
  backend_port = 10000
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  probe_id = azurerm_lb_probe.probe.id
}

resource "azurerm_lb_rule" "stun" {
  name = "${var.prefix}-stun"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.main.id
  protocol = "Udp"
  frontend_ip_configuration_name = "${var.prefix}-vip"
  frontend_port = 3478
  backend_port = 3478
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  probe_id = azurerm_lb_probe.probe.id
}

resource "azurerm_lb_rule" "turns" {
  name = "${var.prefix}-turns"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.main.id
  protocol = "Tcp"
  frontend_ip_configuration_name = "${var.prefix}-vip"
  frontend_port = 5349
  backend_port = 5349
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  probe_id = azurerm_lb_probe.probe.id
}