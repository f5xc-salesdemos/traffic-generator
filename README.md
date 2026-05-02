# f5xc-salesdemos

[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for workflow rules,
branch naming, and CI requirements.

## Terraform Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 3.8.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.71.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_linux_virtual_machine.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azuread_user.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_target_fqdn"></a> [target\_fqdn](#input\_target\_fqdn) | FQDN of the F5 XC load balancer to target | `string` | n/a | yes |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | SSH admin username for the VM | `string` | `"azureuser"` | no |
| <a name="input_deployer"></a> [deployer](#input\_deployer) | Override for deployer identifier (auto-resolved from Azure AD if empty). Required for service principal or managed identity authentication. | `string` | `""` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | OS disk size in GB | `number` | `64` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label used in resource group naming and tags | `string` | `"lab"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for all resources | `string` | `"eastus2"` | no |
| <a name="input_ssh_public_key_path"></a> [ssh\_public\_key\_path](#input\_ssh\_public\_key\_path) | Path to the SSH public key file | `string` | `"~/.ssh/id_ed25519.pub"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged with standard tags (component, environment, deployer, managed\_by) | `map(string)` | `{}` | no |
| <a name="input_target_origin_ip"></a> [target\_origin\_ip](#input\_target\_origin\_ip) | Direct origin IP for bypass testing | `string` | `""` | no |
| <a name="input_tool_tier"></a> [tool\_tier](#input\_tool\_tier) | Tool installation tier: standard (default) or full (includes ZAP, Metasploit) | `string` | `"standard"` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | Azure VM size (F16s\_v2: 16 vCPU compute-optimized, validated by benchmark) | `string` | `"Standard_F16s_v2"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_component"></a> [component](#output\_component) | Component name |
| <a name="output_deployer"></a> [deployer](#output\_deployer) | Resolved deployer identifier |
| <a name="output_environment"></a> [environment](#output\_environment) | Environment label |
| <a name="output_location"></a> [location](#output\_location) | Azure region |
| <a name="output_nsg_id"></a> [nsg\_id](#output\_nsg\_id) | Resource ID of the network security group |
| <a name="output_nsg_name"></a> [nsg\_name](#output\_nsg\_name) | Name of the network security group |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | Private IP address of the VM |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | Public IP address of the VM |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource ID of the resource group |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group |
| <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command) | SSH command to connect to the VM |
| <a name="output_status_check"></a> [status\_check](#output\_status\_check) | SSH command to check provisioning status |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Resource ID of the subnet |
| <a name="output_target_fqdn"></a> [target\_fqdn](#output\_target\_fqdn) | Target FQDN the traffic generator is configured to attack |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | Resource ID of the virtual machine |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | Name of the virtual machine |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | Name of the virtual network |
<!-- END_TF_DOCS -->

## License

See [LICENSE](LICENSE).
