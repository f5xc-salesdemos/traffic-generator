output "public_ip" {
  description = "Public IP address of the traffic generator VM"
  value       = azurerm_public_ip.traffic_gen.ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the traffic generator"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.traffic_gen.ip_address}"
}

output "target_fqdn" {
  description = "Target FQDN the traffic generator is configured to attack"
  value       = var.target_fqdn
}

output "status_check" {
  description = "SSH command to check provisioning status"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.traffic_gen.ip_address} cat /opt/traffic-generator/status.json"
}

output "resource_group" {
  description = "Resource group containing all traffic generator resources"
  value       = local.resource_group_name
}
