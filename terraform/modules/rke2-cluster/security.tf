# security.tf - Security-related resources for RKE2 cluster module

# Common Security Group for all RKE2 nodes
resource "aws_security_group" "rke2_common" {
  name        = "${var.cluster_name}-common-sg"
  description = "Common security group for RKE2 cluster nodes"
  vpc_id      = local.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access from specific CIDR blocks
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_access_cidr
    description = "SSH access"
  }

  # Allow all traffic between cluster nodes
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Internal cluster communication"
  }

  # Add custom worker rules if specified
  dynamic "ingress" {
    for_each = var.additional_worker_sg_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  tags = merge(local.common_tags, { "Name" = "${var.cluster_name}-common-sg" })
}

# Master Node Security Group
resource "aws_security_group" "rke2_master" {
  name        = "${var.cluster_name}-master-sg"
  description = "Security group for RKE2 master nodes"
  vpc_id      = local.vpc_id

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.api_access_cidr
    description = "Kubernetes API"
  }

  # RKE2 supervisor API
  ingress {
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    self        = true
    description = "RKE2 supervisor API"
  }

  # Add custom master rules if specified
  dynamic "ingress" {
    for_each = var.additional_master_sg_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  tags = merge(local.common_tags, { "Name" = "${var.cluster_name}-master-sg" })
}
