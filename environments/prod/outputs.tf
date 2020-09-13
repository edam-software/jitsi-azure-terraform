//output "meet_ip" {
//  depends_on = [azurerm_linux_virtual_machine_scale_set.main, data.azurerm_public_ips.meet]
//  value = data.azurerm_public_ips.meet.public_ips[0]
//}

output "bastion_ip" {
  value = data.azurerm_public_ip.bastion.ip_address
}

output "vip" {
  value = data.azurerm_public_ip.web.ip_address
}

output "fqdn" {
  value = data.azurerm_public_ip.web.fqdn
}