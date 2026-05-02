# ---------------------------------------------------------
# General
# ---------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "deployer" {
  description = "Override for deployer identifier (auto-resolved from Azure AD if empty). Required for service principal or managed identity authentication."
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Environment label used in resource group naming and tags"
  type        = string
  default     = "lab"
}

variable "tags" {
  description = "Additional tags merged with standard tags (component, environment, deployer, managed_by)"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------
# Compute
# ---------------------------------------------------------

variable "vm_size" {
  description = "Azure VM size (F16s_v2: 16 vCPU compute-optimized, validated by benchmark)"
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

variable "disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 64
}

# ---------------------------------------------------------
# Component-Specific
# ---------------------------------------------------------

variable "target_fqdn" {
  description = "FQDN of the F5 XC load balancer to target"
  type        = string
}

variable "target_origin_ip" {
  description = "Direct origin IP for bypass testing"
  type        = string
  default     = ""
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
