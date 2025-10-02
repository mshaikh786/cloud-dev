# Use the RKE2 Cluster Module
module "rke2_cluster" {
  source = "../../modules/rke2-cluster"

  cluster_name = "test-cluster"

  # Use existing VPC and subnets by CIDR
  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = [data.aws_subnet.private.id, data.aws_subnet.public.id]

  # Use existing SSH Key
  key_name = "rke2-common" # Replace with your actual key name

  # Default AMI
  default_ami_id = data.aws_ami.ubuntu.id

  # Disable IAM role creation
  create_custom_iam_role = true

  # Security settings
  ssh_access_cidr = ["0.0.0.0/0"] # Restrict this in production
  api_access_cidr = ["0.0.0.0/0"] # Restrict this in production

  # Add HTTP and HTTPS access to worker nodes
  additional_worker_sg_rules = [
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    }
  ]

  # Add HTTP and HTTPS access to master nodes
  additional_master_sg_rules = [
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    },
    {
      type        = "ingress"
      from_port   = 32000
      to_port     = 32000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Kubeflow access"
    }
  ]

  # Master node configuration - in public subnet
  master_node_config = {
    count                       = 1
    instance_type               = "t3.xlarge"
    root_volume_size            = 128
    subnet_ids                  = [data.aws_subnet.public.id]
    associate_public_ip_address = true
    private_ips                 = ["10.0.1.10"]
  }

  # Worker node configuration - in private subnet
  cpu_worker_configs = [
    {
      count            = 1
      root_volume_size = 128
      instance_type    = "c4.xlarge"
      subnet_ids       = [data.aws_subnet.private.id]
      private_ips      = ["10.0.0.10", "10.0.0.11", "10.0.0.12"] # Private IP for worker node
    }
  ]
  gpu_worker_configs = [
    {
      count            = 1
      instance_type    = "g4dn.xlarge"
      subnet_ids       = [data.aws_subnet.private.id]
      private_ips      = ["10.0.0.41"]
      root_volume_size = 128
      # Private IP for worker node

      # Spot instance configuration
      use_spot_instances                  = true
      spot_price                          = "0.50" # Set your maximum bid price (optional)
      spot_type                           = "persistent"
      spot_wait_for_fulfillment           = true
      spot_instance_interruption_behavior = "terminate"
    }
  ]
  # Tags
  common_tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
karpenter_nodes_tags = {
  cluster    = "test-cluster"
  managed_by = "karpenter"
}
}
