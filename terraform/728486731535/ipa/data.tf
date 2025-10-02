# data.tf - Data sources for looking up AWS resources

# Find the latest Amazon Linux 2 AMI
data "aws_ami" "rocky_9_2" {
  most_recent = true
  owners      = ["792107900819"]

  filter {
    name   = "name"
    values = ["Rocky-9-EC2-LVM-9.2-20230513.0.x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# Find VPC by CIDR block
data "aws_vpc" "selected" {
  filter {
    name   = "cidr-block"
    values = ["10.0.0.0/16"] # Replace with your VPC CIDR
  }
}

# Find private subnet by CIDR block
data "aws_subnet" "private" {
  filter {
    name   = "cidr-block"
    values = ["10.0.0.0/24"] # Replace with your private subnet CIDR
  }

  vpc_id = data.aws_vpc.selected.id
}

# Find public subnet by CIDR block
data "aws_subnet" "public" {
  filter {
    name   = "cidr-block"
    values = ["10.0.1.0/24"] # Replace with your public subnet CIDR
  }

  vpc_id = data.aws_vpc.selected.id
}


