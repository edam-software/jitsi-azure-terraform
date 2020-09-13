/*
    https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart

    80 TCP - for SSL certificate verification / renewal with Let's Encrypt
    443 TCP - for general access to Jitsi Meet
    10000 UDP - for general network video/audio communications
    22 TCP - if you access you server using SSH (change the port accordingly if it's not 22)
    3478 UDP - for quering the stun server (coturn, optional, needs config.js change to enable it)
    5349 TCP - for fallback network video/audio communications over TCP (when UDP is blocked for example), served by coturn


    Open (from Meet Web) to the videobridges only

    5222 TCP (for Prosody)
    5347 TCP (for Jicofo)

*/

resource "azurerm_network_security_group" "main" {
    name                = "${var.prefix}-main-nsg"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    tags = local.tags
}

resource "azurerm_network_security_group" "bastion" {
    name                = "${var.prefix}-bastion-sg"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    tags = local.tags
}


# bastion VM
resource "azurerm_network_security_rule" "admin-ssh" {
    name                       = "${var.prefix}-allow-admin-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_ip
    destination_address_prefix = "*"
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.bastion.name
}

# first rule should be enough
resource "azurerm_network_security_rule" "ssh-bastion" {
    name                       = "${var.prefix}-allow-ssh-bastion"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_linux_virtual_machine.bastion.public_ip_address
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.bastion.name
}

# Once traffic matches a rule, processing stops.
resource "azurerm_network_security_rule" "block-ssh-bastion" {
    depends_on = [data.azurerm_public_ip.bastion]
    name                       = "${var.prefix}-block-ssh-bastion"
    priority                   = 1200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = data.azurerm_public_ip.bastion.ip_address
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.bastion.name
}

# LB VIP

resource "azurerm_network_security_rule" "bastion-internal-ssh" {
    depends_on = [data.azurerm_public_ip.bastion]
    name                       = "${var.prefix}-bastion-internal-ssh"
    priority                   = 1300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_subnet.bastion.address_prefix
    destination_address_prefix = azurerm_subnet.internal.address_prefix
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "block-ssh-lb" {
    depends_on = [data.azurerm_public_ip.bastion]
    name                       = "${var.prefix}-block-ssh-lb"
    priority                   = 1400
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "main-https" {
    name                       = "${var.prefix}-nginx"
    priority                   = 1500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}

# TODO Allow on first run
resource "azurerm_network_security_rule" "main-http" {
    name                       = "${var.prefix}-letsencrypt"
    priority                   = 1600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "main-tcp-media" {
    name                       = "${var.prefix}-media_tcp"
    priority                   = 1700
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4443"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "main-udp" {
    name                       = "${var.prefix}-media_udp"
    priority                   = 1800
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "10000"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "main-stun" {
    name                       = "${var.prefix}-stun"
    priority                   = 1900
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "3478"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "main-turns" {
    name                       = "${var.prefix}-turns"
    priority                   = 2000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5349"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}
