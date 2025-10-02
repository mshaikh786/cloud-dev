locals {
  vpc_cidr = "10.0.0.0/16"
  az       = data.aws_availability_zones.available.names[0] # Using only the first AZ
  tags     = var.tags
  region   = "eu-central-1"
}
