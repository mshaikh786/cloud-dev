# RKE2 Cluster Terraform Module

This Terraform module creates and configures an RKE2 Kubernetes cluster on AWS EC2 instances. It provides flexibility for setting up various node types including master nodes, CPU worker nodes, GPU worker nodes, and general-purpose server nodes.

## Features

- Creates a fully configurable RKE2 cluster in AWS
- Support for master nodes, CPU workers, GPU workers, and general server nodes
- Support for both on-demand and spot instances for cost optimization
- Customizable instance types, AMIs, and configuration for each node group
- Configurable security groups with additional rule support
- IAM role and instance profile management
- VPC and subnet configuration with CIDR lookup support
- Volume configuration for root and additional EBS volumes

## Prerequisites

- Terraform >= 0.13.0
- AWS provider
- An existing VPC and subnets (or the module can look them up by CIDR)
- AWS credentials configured

## Usage

### Basic Example

```hcl
module "rke2_cluster" {
  source = "path/to/module"

  cluster_name = "my-rke2-cluster"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345678", "subnet-87654321"]
  key_name     = "my-ssh-key"

  master_node_config = {
    count         = 3
    instance_type = "t3.large"
    root_volume_size = 50
  }

  cpu_worker_configs = [
    {
      count         = 3
      instance_type = "m5.large"
      root_volume_size = 50
    }
  ]
}
```

### Advanced Example with Spot Instances

```hcl
module "rke2_cluster" {
  source = "path/to/module"

  cluster_name = "my-advanced-rke2-cluster"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345678", "subnet-87654321"]
  key_name     = "my-ssh-key"
  common_tags  = {
    Environment = "production"
    Project     = "kubernetes"
  }

  # Security configuration
  ssh_access_cidr = ["10.0.0.0/8", "192.168.0.0/16"]
  api_access_cidr = ["10.0.0.0/8"]
  
  additional_master_sg_rules = [
    {
      type        = "ingress"
      from_port   = 8472
      to_port     = 8472
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Canal/Flannel VXLAN"
    }
  ]

  # IAM configuration
  iam_role_name_prefix    = "production-"
  additional_iam_policies = ["arn:aws:iam::aws:policy/AmazonECR-FullAccess"]

  # Master node configuration (on-demand for stability)
  master_node_config = {
    count         = 3
    instance_type = "t3.large"
    root_volume_size = 100
    root_volume_type = "gp3"
    additional_ebs_volumes = {
      data = {
        device_name = "/dev/sdf"
        volume_size = 200
        volume_type = "gp3"
      }
    }
  }

  # CPU worker node groups (mix of on-demand and spot)
  cpu_worker_configs = [
    {
      count         = 3
      instance_type = "m5.xlarge"
      root_volume_size = 100
      additional_ebs_volumes = {
        data = {
          device_name = "/dev/sdf"
          volume_size = 500
          volume_type = "gp3"
        }
      }
    },
    {
      count         = 2
      instance_type = "c5.2xlarge"
      root_volume_size = 100
      use_spot_instances = true
      spot_price = "0.34"  # Optional max price (per hour)
    }
  ]

  # GPU worker node groups with spot instances
  gpu_worker_configs = [
    {
      count         = 2
      instance_type = "g4dn.xlarge"
      root_volume_size = 100
      use_spot_instances = true
      spot_price = "0.50"  # Optional max price (per hour)
    }
  ]
}
```

## Input Variables

### General Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | Name of the RKE2 cluster. Will be used for resource naming | `string` | n/a | yes |
| `common_tags` | Tags to apply to all resources | `map(string)` | `{}` | no |

### Network Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_id` | ID of the VPC where the cluster will be deployed | `string` | `null` | no (if `vpc_cidr` is provided) |
| `subnet_ids` | List of subnet IDs where the cluster nodes will be deployed | `list(string)` | `[]` | no (if `subnet_cidrs` is provided) |
| `vpc_cidr` | CIDR block of the VPC to use (will lookup the VPC ID if vpc_id is not provided) | `string` | `null` | no (if `vpc_id` is provided) |
| `subnet_cidrs` | List of subnet CIDR blocks to use (will lookup the subnet IDs if subnet_ids is not provided) | `list(string)` | `[]` | no (if `subnet_ids` is provided) |

### Security Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `key_name` | Name of the AWS key pair to use for SSH access | `string` | `null` | no |
| `ssh_access_cidr` | CIDR blocks allowed SSH access to instances | `list(string)` | `["0.0.0.0/0"]` | no |
| `api_access_cidr` | CIDR blocks allowed to access the Kubernetes API | `list(string)` | `["0.0.0.0/0"]` | no |
| `additional_master_sg_rules` | Additional security group rules for master nodes | `list(object)` | `[]` | no |
| `additional_worker_sg_rules` | Additional security group rules for worker nodes | `list(object)` | `[]` | no |

### IAM Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `iam_role_name_prefix` | Prefix for IAM role names | `string` | `""` | no |
| `additional_iam_policies` | List of additional IAM policy ARNs to attach to the instance role | `list(string)` | `[]` | no |
| `create_custom_iam_role` | Whether to create a custom IAM role for the instances | `bool` | `true` | no |
| `existing_iam_instance_profile_name` | Name of an existing IAM instance profile to use instead of creating one | `string` | `null` | no |

### Instance Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `default_ami_id` | Default AMI ID to use for nodes if not specified in node configs | `string` | Latest Amazon Linux 2 AMI | no |
| `master_node_config` | Configuration for master nodes | `object` | `null` | no |
| `cpu_worker_configs` | List of configurations for CPU worker node groups | `list(object)` | `[]` | no |
| `gpu_worker_configs` | List of configurations for GPU worker node groups | `list(object)` | `[]` | no |
| `server_node_configs` | List of configurations for server node groups | `list(object)` | `[]` | no |

#### Node Configuration Object Structure

Each node configuration (master, CPU worker, GPU worker, server) accepts the following attributes:

```hcl
{
  count                       = number             # Number of nodes to create
  ami_id                      = string (optional)  # AMI ID for the node (defaults to default_ami_id)
  instance_type               = string             # EC2 instance type
  associate_public_ip_address = bool (optional)    # Whether to assign a public IP (default: false)
  subnet_ids                  = list(string) (opt) # Specific subnet IDs for this node group
  private_ips                 = list(string) (opt) # Specific private IPs to assign
  root_volume_size            = number (optional)  # Root volume size in GB (default: 50)
  root_volume_type            = string (optional)  # Root volume type (default: "gp3")
  additional_ebs_volumes      = map(object) (opt)  # Additional EBS volumes to attach
  user_data                   = string (optional)  # Custom user data script
  
  # Spot instance configuration
  use_spot_instances               = bool (optional)    # Whether to use spot instances (default: false)
  spot_price                       = string (optional)  # Maximum bid price for spot instances
  spot_type                        = string (optional)  # Spot request type (default: "persistent")
  spot_wait_for_fulfillment        = bool (optional)    # Whether to wait for fulfillment (default: true)
  spot_instance_interruption_behavior = string (opt)    # Interruption behavior (default: "terminate")
}
```

## Output Values

### Cluster Information

| Name | Description |
|------|-------------|
| `cluster_name` | Name of the RKE2 cluster |
| `vpc_id` | VPC ID used for the cluster |
| `subnet_ids` | Subnet IDs used for the cluster |
| `node_counts` | Count of nodes by type (master, cpu_workers, gpu_workers, servers, total) |

### Node Information

| Name | Description |
|------|-------------|
| `master_nodes` | Master node instances |
| `master_node_ids` | IDs of master node instances |
| `master_private_ips` | Private IPs of master nodes |
| `master_public_ips` | Public IPs of master nodes (if available) |
| `cpu_worker_nodes` | Map of CPU worker nodes by group and index |
| `cpu_worker_private_ips` | Private IPs of CPU worker nodes grouped by worker group |
| `cpu_worker_public_ips` | Public IPs of CPU worker nodes grouped by worker group (if available) |
| `gpu_worker_nodes` | Map of GPU worker on-demand nodes by group and index |
| `gpu_worker_spot_nodes` | Map of GPU worker spot instances by group and index |
| `gpu_worker_spot_instance_ids` | Instance IDs of GPU worker spot instances |
| `gpu_worker_private_ips` | Private IPs of GPU worker nodes (both on-demand and spot) grouped by worker group |
| `gpu_worker_public_ips` | Public IPs of GPU worker nodes (both on-demand and spot) grouped by worker group (if available) |
| `server_nodes` | Map of server nodes by group and index |
| `server_private_ips` | Private IPs of server nodes grouped by server group |
| `server_public_ips` | Public IPs of server nodes grouped by server group (if available) |
| `all_node_ips` | All node IPs grouped by type |
| `all_node_public_ips` | All node public IPs grouped by type (if available) |

### Security and IAM Information

| Name | Description |
|------|-------------|
| `security_groups` | Security groups created for the cluster |
| `instance_profile` | Instance profile used for cluster nodes |

## Spot Instance Support

This module supports using AWS Spot Instances for cost optimization:

1. **Configuring Spot Instances**: Add the `use_spot_instances = true` parameter to any node group to use spot instances.

2. **Spot Price**: Optionally set a maximum bid price with the `spot_price` parameter.

3. **Mixed Deployment**: You can mix on-demand and spot instances in your cluster for an optimal price/stability balance.

4. **Interruption Handling**: Configure spot instance behavior on interruption using the `spot_instance_interruption_behavior` parameter.

### Spot Instance Best Practices

- Use on-demand instances for critical components like master nodes
- Use spot instances for stateless workloads that can tolerate interruption
- Set appropriate node labels in Kubernetes to identify spot vs on-demand nodes
- Configure node draining before termination using a tool like AWS Node Termination Handler

## Notes

1. At least one of `vpc_id` or `vpc_cidr` must be provided.
2. At least one of `subnet_ids` or `subnet_cidrs` must be provided.
3. If you specify `private_ips` for a node group, ensure that the number of IPs is at least equal to the `count` of nodes.
4. The module supports creating multiple CPU worker groups, GPU worker groups, and server groups with different configurations.
5. Spot instances can be interrupted when demand increases or prices exceed your bid, so plan your workloads accordingly.