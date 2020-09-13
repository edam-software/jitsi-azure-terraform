//data "azurerm_public_ips" "meet" {
//  resource_group_name = azurerm_resource_group.main.name
//  name_prefix =  "${var.prefix}-vip"
//  #attached = true
//}

data "azurerm_public_ip" "bastion" {
  depends_on = [azurerm_linux_virtual_machine.bastion]
  name = "${var.prefix}-bastion"
  resource_group_name = azurerm_resource_group.main.name
}

data "azurerm_public_ip" "web" {
  depends_on = [azurerm_public_ip.web]
  name = "${var.prefix}-web"
  resource_group_name = azurerm_resource_group.main.name
}

data "azurerm_client_config" "current" {
}
