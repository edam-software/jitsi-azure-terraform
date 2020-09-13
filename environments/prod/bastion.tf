resource "azurerm_network_interface" "bastion" {
  name = "${var.prefix}-bastion"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location

  ip_configuration {
    name = "${var.prefix}-bastion"
    subnet_id = azurerm_subnet.bastion.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_network_interface_security_group_association" "bastion" {
  network_interface_id = azurerm_network_interface.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource azurerm_linux_virtual_machine "bastion" {
  name = "${var.prefix}-bastion"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  admin_username = var.ssh_username
  size = var.bastion_sku
  custom_data = base64encode(templatefile("${path.module}/templates/ansible_setup.tpl",
  { somevar = ""}
  ))
  network_interface_ids = [
    azurerm_network_interface.bastion.id]

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
    storage_account_type = "Standard_LRS"
    caching = "ReadWrite"
  }
}