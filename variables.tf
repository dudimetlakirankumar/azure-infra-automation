variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the VM will be created"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed"
}

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "vm_size" {
  type        = string
  description = "Size of the virtual machine"
  default     = "Standard_DS1_v2"
}

variable "admin_username" {
  type        = string
  description = "Username for accessing the virtual machine"
}

variable "admin_password" {
  type        = string
  description = "Password for accessing the virtual machine"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for accessing the virtual machine (optional)"
}
