# Jitsi network and LBs

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "${var.prefix}-bastion"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "bastion" {
  name = "${var.prefix}-bastion"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  allocation_method = "Dynamic"
  sku = "Basic"
}

resource "azurerm_public_ip" "web" {
  name                = "${var.prefix}-web"
  domain_name_label = var.prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "image_vm" {
  name                = "${var.prefix}-image-nic"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}
