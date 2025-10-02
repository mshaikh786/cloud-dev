# data.tf - Data sources for RKE2 cluster module

# Look up VPC based on CIDR block if vpc_id is not provided
data "aws_vpc" "selected" {
  count = var.vpc_id == null && var.vpc_cidr != null ? 1 : 0

  filter {
    name   = "cidr-block"
    values = [var.vpc_cidr]
  }
}

# Look up subnets based on CIDR blocks if subnet_ids are not provided
data "aws_subnets" "selected" {
  count = length(var.subnet_ids) == 0 && length(var.subnet_cidrs) > 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = var.subnet_cidrs
  }
}

# Get the latest Amazon Linux 2 AMI if not specified
data "aws_ami" "amazon_linux_2" {
  count = var.default_ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
