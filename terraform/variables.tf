variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name for the Azure resource group"
  type        = string
  default     = "rg-traffic-generator"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "vm_size" {
  description = "Azure VM size (F16s_v2: 16 vCPU compute-optimized — best throughput per dollar, validated by A/B/C/D benchmark)"
  type        = string
  default     = "Standard_F16s_v2"
}

variable "admin_username" {
  description = "SSH admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "environment_tag" {
  description = "Environment tag applied to all resources"
  type        = string
  default     = "lab"
}

variable "target_fqdn" {
  description = "FQDN of the F5 XC load balancer to attack"
  type        = string
}

variable "target_origin_ip" {
  description = "Direct origin IP for bypass testing"
  type        = string
  default     = ""
}

variable "disk_size_gb" {
  description = "OS disk size in GB (larger disk for security tools)"
  type        = number
  default     = 64
}

variable "tool_tier" {
  description = "Tool installation tier: standard (default) or full (includes ZAP, Metasploit)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "full"], var.tool_tier)
    error_message = "tool_tier must be \"standard\" or \"full\"."
  }
}
