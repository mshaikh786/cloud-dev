# Create a security group for RKE2 jump host
resource "aws_security_group" "jump_host_sg" {
  name        = "rke2-jump-host-sg"
  description = "Security group for RKE2 jump host"
  vpc_id      = data.aws_vpc.selected.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
    description = "SSH Access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name      = "rke2-jump-host-sg"
    CreatedBy = "Terraform"
  }
}

# Create an IAM role for the jump host instance
resource "aws_iam_role" "jump_host_role" {
  name = "rke2-jump-host-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "rke2-jump-host-role"
    CreatedBy = "Terraform"
  }
}

# Create an IAM instance profile for the jump host role
resource "aws_iam_instance_profile" "jump_host_profile" {
  name = "rke2-jump-host-profile"
  role = aws_iam_role.jump_host_role.name

  tags = {
    Name      = "rke2-jump-host-profile"
    CreatedBy = "Terraform"
  }
}

# Create an Elastic IP for the jump host
resource "aws_eip" "jump_host_eip" {
  domain = "vpc"
  tags = {
    Name      = "rke2-jump-host-eip"
    CreatedBy = "Terraform"
  }
}

# Create the jump host EC2 instance
resource "aws_instance" "jump_host" {
  ami                         = data.aws_ami.rocky_9_2.id
  instance_type               = var.jump_host_instance_type
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.jump_host_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.jump_host_profile.name
  key_name                    = var.ssh_key_name

  root_block_device {
    volume_size = var.jump_host_volume_size
    volume_type = var.jump_host_volume_type
  }

  tags = {
    Name      = "rke2-jump-host"
    CreatedBy = "Terraform"
  }
}

# Associate the Elastic IP with the jump host instance
resource "aws_eip_association" "jump_host_eip_assoc" {
  instance_id   = aws_instance.jump_host.id
  allocation_id = aws_eip.jump_host_eip.id
}

# Output important information
output "jump_host_public_ip" {
  value = aws_eip.jump_host_eip.public_ip
}

output "jump_host_private_ip" {
  value = aws_instance.jump_host.private_ip
}

output "jump_host_id" {
  value = aws_instance.jump_host.id
}
