# main.tf - IPA Server Instance Configuration

# Create a security group for IPA server
resource "aws_security_group" "ipa_sg" {
  name        = "ipa-server-sg"
  description = "Security group for IPA server"
  vpc_id      = data.aws_vpc.selected.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS TCP"
  }
  # DNS
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "DNS TCP"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "DNS UDP"
  }

  # Kerberos
  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Kerberos TCP"
  }

  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Kerberos UDP"
  }

  # LDAP
  ingress {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "LDAP"
  }

  # LDAPS
  ingress {
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "LDAPS"
  }

  # Kerberos admin
  ingress {
    from_port   = 749
    to_port     = 749
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Kerberos admin"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }


  # NTP
  ingress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "NTP"
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
    Name = "ipa-server-sg"
  }
}

# Create an IAM role for the IPA instance
resource "aws_iam_role" "ipa_role" {
  name = "ipa-server-role"

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
}

# Create an IAM instance profile for the IPA role
resource "aws_iam_instance_profile" "ipa_profile" {
  name = "ipa-server-profile"
  role = aws_iam_role.ipa_role.name
}

# Create an Elastic IP for the IPA server
resource "aws_eip" "ipa_eip" {
  domain = "vpc"
  tags = {
    Name = "ipa-server-eip"
  }
}

# Create the IPA EC2 instance
resource "aws_instance" "ipa_server" {
  ami                    = data.aws_ami.rocky_9_2.id
  instance_type          = "t3.medium" # Recommended for IPA Server
  subnet_id              = data.aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ipa_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ipa_profile.name
  key_name               = "rke2-common" # Replace with your SSH key pair name
  user_data              = file("userdata.sh")
  private_ip             = "10.0.1.110"

  root_block_device {
    volume_size = 30 # Recommended size for IPA server
    volume_type = "gp3"
  }


  tags = {
    Name = "ipa-server"
  }
}

# Associate the Elastic IP with the IPA instance
resource "aws_eip_association" "ipa_eip_assoc" {
  instance_id   = aws_instance.ipa_server.id
  allocation_id = aws_eip.ipa_eip.id
}

# Output important information
output "ipa_server_public_ip" {
  value = aws_eip.ipa_eip.public_ip
}

output "ipa_server_private_ip" {
  value = aws_instance.ipa_server.private_ip
}

output "ipa_server_id" {
  value = aws_instance.ipa_server.id
}
