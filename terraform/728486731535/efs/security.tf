# EFS Security Group
resource "aws_security_group" "efs_security_group" {
  name        = "efs-security-group"
  description = "Security group for EFS mounts"
  vpc_id      = data.aws_vpc.selected.id

  # NFS ingress rule (port 2049)
  ingress {
    description = "NFS ingress from VPC private subnets"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # Egress rule - allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "efs-sg"
    Terraform = "true"
  }
}