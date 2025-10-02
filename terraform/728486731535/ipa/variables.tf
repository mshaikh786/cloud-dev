# variables.tf - Variables for IPA Server Configuration

variable "ipa_domain" {
  description = "Domain name for IPA server"
  type        = string
  default     = "example.com" # Change to your domain
}

variable "ipa_realm" {
  description = "Realm name for IPA server (typically domain name in uppercase)"
  type        = string
  default     = "EXAMPLE.COM" # Change to your realm
}

variable "ipa_hostname" {
  description = "Hostname for IPA server"
  type        = string
  default     = "ipa.example.com" # Change to your hostname
}

variable "instance_type" {
  description = "EC2 instance type for IPA server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "rke2-islam" # Change to your key pair
}

variable "dns_forwarder" {
  description = "DNS forwarder for IPA server"
  type        = string
  default     = "8.8.8.8" # Change to your preferred DNS forwarder
}

variable "admin_password" {
  description = "Admin password for IPA server"
  type        = string
  default     = "StrongAdminPassword123" # Change to a secure password
  sensitive   = true
}

variable "directory_password" {
  description = "Directory password for IPA server"
  type        = string
  default     = "StrongDirectoryPassword123" # Change to a secure password
  sensitive   = true
}

variable "volume_size" {
  description = "Root volume size for IPA server in GB"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Name        = "ipa-server"
    Environment = "production"
    Managed_by  = "terraform"
  }
}
