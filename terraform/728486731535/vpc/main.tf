data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "tf-rke2-vpc"
  cidr = local.vpc_cidr

  azs             = [local.az]                         # Using only one AZ
  private_subnets = [cidrsubnet(local.vpc_cidr, 8, 0)] # Single private subnet
  public_subnets  = [cidrsubnet(local.vpc_cidr, 8, 1)] # Single public subnet
  # intra_subnets   = [cidrsubnet(local.vpc_cidr, 8, 52)] # Single intra subnet

  enable_ipv6            = false
  create_egress_only_igw = true

  public_subnet_ipv6_prefixes  = [0]
  private_subnet_ipv6_prefixes = [3]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = false
  create_flow_log_cloudwatch_iam_role  = false
  create_flow_log_cloudwatch_log_group = false

  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true

  create_multiple_public_route_tables = false # Changed to false as we have only one public subnet

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
