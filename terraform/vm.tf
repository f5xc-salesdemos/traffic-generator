resource "azurerm_linux_virtual_machine" "traffic_gen" {
  name                = "vm-traffic-generator"
  resource_group_name = azurerm_resource_group.traffic_gen.name
  location            = azurerm_resource_group.traffic_gen.location
  size                = var.vm_size

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  network_interface_ids = [azurerm_network_interface.traffic_gen.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    target_fqdn     = var.target_fqdn
    target_origin_ip = var.target_origin_ip
    tool_tier        = var.tool_tier
  }))

  tags = azurerm_resource_group.traffic_gen.tags
}
