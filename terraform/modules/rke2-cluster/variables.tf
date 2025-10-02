# variables.tf - Input variables for RKE2 cluster module

#
# General Configuration
#
variable "cluster_name" {
  description = "Name of the RKE2 cluster. Will be used for resource naming"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#
# Network Configuration
#
variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed (optional if vpc_cidr is provided)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs where the cluster nodes will be deployed (optional if subnet_cidrs is provided)"
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC to use (will lookup the VPC ID if vpc_id is not provided)"
  type        = string
  default     = null
}

variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks to use (will lookup the subnet IDs if subnet_ids is not provided)"
  type        = list(string)
  default     = []
}

#
# Security Configuration
#
variable "key_name" {
  description = "Name of the AWS key pair to use for SSH access"
  type        = string
  default     = null
}

variable "ssh_access_cidr" {
  description = "CIDR blocks allowed SSH access to instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_access_cidr" {
  description = "CIDR blocks allowed to access the Kubernetes API"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_master_sg_rules" {
  description = "Additional security group rules for master nodes"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

#
# IAM Configuration
#
variable "iam_role_name_prefix" {
  description = "Prefix for IAM role names"
  type        = string
  default     = ""
}

variable "additional_iam_policies" {
  description = "List of additional IAM policy ARNs to attach to the instance role"
  type        = list(string)
  default     = []
}

variable "create_custom_iam_role" {
  description = "Whether to create a custom IAM role for the instances"
  type        = bool
  default     = true
}

variable "existing_iam_instance_profile_name" {
  description = "Name of an existing IAM instance profile to use instead of creating one"
  type        = string
  default     = null
}

variable "additional_worker_sg_rules" {
  description = "Additional security group rules for worker nodes"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

#
# Instance Configuration
#
variable "default_ami_id" {
  description = "Default AMI ID to use for nodes if not specified in node configs"
  type        = string
  default     = null
}

variable "master_node_config" {
  description = "Configuration for master nodes"
  type = object({
    count                       = number
    ami_id                      = optional(string)
    instance_type               = string
    associate_public_ip_address = optional(bool, false)
    subnet_ids                  = optional(list(string))
    private_ips                 = optional(list(string))
    root_volume_size            = optional(number, 50)
    root_volume_type            = optional(string, "gp3")
    additional_ebs_volumes = optional(map(object({
      device_name = string
      volume_size = number
      volume_type = string
    })), {})
    user_data = optional(string)
    # Spot instance configuration
    use_spot_instances               = optional(bool, false)
    spot_price                       = optional(string)
    spot_type                        = optional(string, "persistent")
    spot_wait_for_fulfillment        = optional(bool, true)
    spot_instance_interruption_behavior = optional(string, "terminate")
  })
  default = null
}

variable "cpu_worker_configs" {
  description = "List of configurations for CPU worker node groups"
  type = list(object({
    count                       = number
    ami_id                      = optional(string)
    instance_type               = string
    associate_public_ip_address = optional(bool, false)
    subnet_ids                  = optional(list(string))
    private_ips                 = optional(list(string))
    root_volume_size            = optional(number, 50)
    root_volume_type            = optional(string, "gp3")
    additional_ebs_volumes = optional(map(object({
      device_name = string
      volume_size = number
      volume_type = string
    })), {})
    user_data = optional(string)
    # Spot instance configuration
    use_spot_instances               = optional(bool, false)
    spot_price                       = optional(string)
    spot_type                        = optional(string, "persistent")
    spot_wait_for_fulfillment        = optional(bool, true)
    spot_instance_interruption_behavior = optional(string, "terminate")
  }))
  default = []
}

variable "gpu_worker_configs" {
  description = "List of configurations for GPU worker node groups"
  type = list(object({
    count                       = number
    ami_id                      = optional(string)
    instance_type               = string
    associate_public_ip_address = optional(bool, false)
    subnet_ids                  = optional(list(string))
    private_ips                 = optional(list(string))
    root_volume_size            = optional(number, 50)
    root_volume_type            = optional(string, "gp3")
    additional_ebs_volumes = optional(map(object({
      device_name = string
      volume_size = number
      volume_type = string
    })), {})
    user_data = optional(string)
    # Spot instance configuration
    use_spot_instances               = optional(bool, false)
    spot_price                       = optional(string)
    spot_type                        = optional(string, "persistent")
    spot_wait_for_fulfillment        = optional(bool, true)
    spot_instance_interruption_behavior = optional(string, "terminate")
  }))
  default = []
}

variable "server_node_configs" {
  description = "List of configurations for server node groups"
  type = list(object({
    count                       = number
    ami_id                      = optional(string)
    instance_type               = string
    associate_public_ip_address = optional(bool, false)
    subnet_ids                  = optional(list(string))
    private_ips                 = optional(list(string))
    root_volume_size            = optional(number, 50)
    root_volume_type            = optional(string, "gp3")
    additional_ebs_volumes = optional(map(object({
      device_name = string
      volume_size = number
      volume_type = string
    })), {})
    user_data = optional(string)
    # Spot instance configuration
    use_spot_instances               = optional(bool, false)
    spot_price                       = optional(string)
    spot_type                        = optional(string, "persistent")
    spot_wait_for_fulfillment        = optional(bool, true)
    spot_instance_interruption_behavior = optional(string, "terminate")
  }))
  default = []
}


variable "karpenter_nodes_tags" {
  description = "Tags to apply to karpenter nodes"
  type        = map(string)
  default = {
    cluster    = "test-cluster"
    managed_by = "karpenter"
  }
}
