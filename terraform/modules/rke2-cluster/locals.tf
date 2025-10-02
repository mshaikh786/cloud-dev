# locals.tf - Local variables for RKE2 cluster module

locals {
  # Determine VPC and subnet IDs based on inputs
  vpc_id     = var.vpc_id != null ? var.vpc_id : (var.vpc_cidr != null ? data.aws_vpc.selected[0].id : null)
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : (length(var.subnet_cidrs) > 0 ? data.aws_subnets.selected[0].ids : [])

  # Set default AMI ID if not provided
  default_ami = var.default_ami_id != null ? var.default_ami_id : (length(data.aws_ami.amazon_linux_2) > 0 ? data.aws_ami.amazon_linux_2[0].id : null)

  # Tags to apply to all resources
  common_tags = merge(var.common_tags, { "ClusterName" = var.cluster_name })

  # Create IAM instance profile name
  instance_profile_name = var.existing_iam_instance_profile_name != null ? var.existing_iam_instance_profile_name : (
    var.create_custom_iam_role ? aws_iam_instance_profile.rke2_instance_profile[0].name : null
  )

  # Prepare the node configurations for for_each
  cpu_worker_nodes = flatten([
    for idx, config in var.cpu_worker_configs : [
      for i in range(config.count) : {
        key       = "${idx}-${i}"
        group_idx = idx
        node_idx  = i
        config    = config
      }
    ] if config != null
  ])

  gpu_worker_nodes = flatten([
    for idx, config in var.gpu_worker_configs : [
      for i in range(config.count) : {
        key       = "${idx}-${i}"
        group_idx = idx
        node_idx  = i
        config    = config
      }
    ] if config != null
  ])

  server_nodes = flatten([
    for idx, config in var.server_node_configs : [
      for i in range(config.count) : {
        key       = "${idx}-${i}"
        group_idx = idx
        node_idx  = i
        config    = config
      }
    ] if config != null
  ])
}