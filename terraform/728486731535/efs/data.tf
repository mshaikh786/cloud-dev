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