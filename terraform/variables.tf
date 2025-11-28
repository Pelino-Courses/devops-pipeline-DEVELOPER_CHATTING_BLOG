variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "devopspipeline"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "switzerlandnorth"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.ssh_public_key) > 0 && (startswith(var.ssh_public_key, "ssh-rsa") || startswith(var.ssh_public_key, "ssh-ed25519"))
    error_message = "SSH public key must be a valid SSH key starting with 'ssh-rsa' or 'ssh-ed25519'."
  }
}
