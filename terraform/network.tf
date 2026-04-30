resource "azurerm_resource_group" "traffic_gen" {
  name     = local.resource_group_name
  location = var.location

  tags = {
    environment = var.environment_tag
    component   = "traffic-generator"
  }
}

resource "azurerm_virtual_network" "traffic_gen" {
  name                = "vnet-traffic-generator"
  address_space       = ["10.201.0.0/16"]
  location            = azurerm_resource_group.traffic_gen.location
  resource_group_name = azurerm_resource_group.traffic_gen.name

  tags = azurerm_resource_group.traffic_gen.tags
}

resource "azurerm_subnet" "traffic_gen" {
  name                 = "snet-traffic-generator"
  resource_group_name  = azurerm_resource_group.traffic_gen.name
  virtual_network_name = azurerm_virtual_network.traffic_gen.name
  address_prefixes     = ["10.201.1.0/24"]
}

resource "azurerm_public_ip" "traffic_gen" {
  name                = "pip-traffic-generator"
  location            = azurerm_resource_group.traffic_gen.location
  resource_group_name = azurerm_resource_group.traffic_gen.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.traffic_gen.tags
}

resource "azurerm_network_security_group" "traffic_gen" {
  name                = "nsg-traffic-generator"
  location            = azurerm_resource_group.traffic_gen.location
  resource_group_name = azurerm_resource_group.traffic_gen.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.traffic_gen.tags
}

resource "azurerm_network_interface" "traffic_gen" {
  name                = "nic-traffic-generator"
  location            = azurerm_resource_group.traffic_gen.location
  resource_group_name = azurerm_resource_group.traffic_gen.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.traffic_gen.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.traffic_gen.id
  }

  tags = azurerm_resource_group.traffic_gen.tags
}

resource "azurerm_network_interface_security_group_association" "traffic_gen" {
  network_interface_id      = azurerm_network_interface.traffic_gen.id
  network_security_group_id = azurerm_network_security_group.traffic_gen.id
}
