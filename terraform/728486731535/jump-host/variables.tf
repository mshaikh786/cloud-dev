variable "jump_host_instance_type" {
  description = "Instance type for the jump host"
  type        = string
  default     = "t3.micro"
}

variable "jump_host_volume_size" {
  description = "Root volume size for the jump host in GB"
  type        = number
  default     = 10
}

variable "jump_host_volume_type" {
  description = "Root volume type for the jump host"
  type        = string
  default     = "gp3"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for the jump host"
  type        = string
  default     = "rke2-common"
}

variable "ssh_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the jump host via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
