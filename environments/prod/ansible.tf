//resource "null_resource" "ansible" {
//
//  provisioner "remote-exec" {
//    connection {
//      type = "ssh"
//      user = "hapa"
//      host = azurerm_linux_virtual_machine.bastion.public_ip_address
//      private_key = file("${path.module}../../../${var.private_key}"
//    }
//  }





