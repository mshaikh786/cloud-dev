# EFS Storage Class Module
module "efs-storage-class" {
  source = "terraform-aws-modules/efs/aws"
  
  # File system
  name           = "tf-efs-storage-class"
  encrypted      = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  
  attach_policy = false
  
  # Mount targets / security group - using a single private subnet
  mount_targets = {
    "${data.aws_subnet.private.availability_zone}" = {
      subnet_id = data.aws_subnet.private.id
      security_groups = [aws_security_group.efs_security_group.id]
    }
  }
  
  security_group_vpc_id = data.aws_vpc.selected.id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC private subnet"
      cidr_blocks = [data.aws_subnet.private.cidr_block]
    }
  }
  
  # Backup policy
  enable_backup_policy = true
  
  # No dependencies needed for this project
  
  tags = {
    Terraform = "true"
    Environment = "Production"
  }
}
