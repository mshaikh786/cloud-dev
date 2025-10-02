# # main.tf - Main resources for RKE2 cluster module

# locals {
#   # Determine VPC and subnet IDs based on inputs
#   vpc_id     = var.vpc_id != null ? var.vpc_id : (var.vpc_cidr != null ? data.aws_vpc.selected[0].id : null)
#   subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : (length(var.subnet_cidrs) > 0 ? data.aws_subnets.selected[0].ids : [])

#   # Set default AMI ID if not provided
#   default_ami = var.default_ami_id != null ? var.default_ami_id : (length(data.aws_ami.amazon_linux_2) > 0 ? data.aws_ami.amazon_linux_2[0].id : null)

#   # Tags to apply to all resources
#   common_tags = merge(var.common_tags, { "ClusterName" = var.cluster_name })

#   # Create IAM instance profile name
#   instance_profile_name = var.existing_iam_instance_profile_name != null ? var.existing_iam_instance_profile_name : (
#     var.create_custom_iam_role ? aws_iam_instance_profile.rke2_instance_profile[0].name : null
#   )

#   # Prepare the node configurations for for_each
#   cpu_worker_nodes = flatten([
#     for idx, config in var.cpu_worker_configs : [
#       for i in range(config.count) : {
#         key       = "${idx}-${i}"
#         group_idx = idx
#         node_idx  = i
#         config    = config
#       }
#     ] if config != null
#   ])

#   gpu_worker_nodes = flatten([
#     for idx, config in var.gpu_worker_configs : [
#       for i in range(config.count) : {
#         key       = "${idx}-${i}"
#         group_idx = idx
#         node_idx  = i
#         config    = config
#       }
#     ] if config != null
#   ])

#   server_nodes = flatten([
#     for idx, config in var.server_node_configs : [
#       for i in range(config.count) : {
#         key       = "${idx}-${i}"
#         group_idx = idx
#         node_idx  = i
#         config    = config
#       }
#     ] if config != null
#   ])
# }

###################
# Master Nodes
###################
resource "aws_instance" "master" {
  count = var.master_node_config != null ? var.master_node_config.count : 0

  ami           = var.master_node_config.ami_id != null ? var.master_node_config.ami_id : local.default_ami
  instance_type = var.master_node_config.instance_type

  subnet_id = element(
    var.master_node_config.subnet_ids != null ? var.master_node_config.subnet_ids : local.subnet_ids,
    count.index % length(var.master_node_config.subnet_ids != null ? var.master_node_config.subnet_ids : local.subnet_ids)
  )

  vpc_security_group_ids = [aws_security_group.rke2_common.id, aws_security_group.rke2_master.id]

  # Use specified private IP if provided
  private_ip                  = (var.master_node_config.private_ips != null && length(var.master_node_config.private_ips) > count.index) ? var.master_node_config.private_ips[count.index] : null
  associate_public_ip_address = var.master_node_config.associate_public_ip_address != null ? var.master_node_config.associate_public_ip_address : false

  key_name             = var.key_name
  iam_instance_profile = local.instance_profile_name != null ? local.instance_profile_name : null

  root_block_device {
    volume_size = var.master_node_config.root_volume_size
    volume_type = var.master_node_config.root_volume_type
    encrypted   = true
    tags        = merge(local.common_tags, { "Name" = "${var.cluster_name}-master-${count.index + 1}-root" })
  }
  user_data = var.master_node_config.user_data
  tags = merge(
    local.common_tags,
    {
      Name       = "${var.cluster_name}-master-${count.index + 1}",
      "NodeType" = "master"
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }
}

###################
# CPU Worker Nodes
###################
resource "aws_instance" "cpu_worker" {
  for_each = {
    for node in local.cpu_worker_nodes : node.key => node
  }

  ami           = each.value.config.ami_id != null ? each.value.config.ami_id : local.default_ami
  instance_type = each.value.config.instance_type

  subnet_id = element(
    each.value.config.subnet_ids != null ? each.value.config.subnet_ids : local.subnet_ids,
    each.value.node_idx % length(each.value.config.subnet_ids != null ? each.value.config.subnet_ids : local.subnet_ids)
  )

  vpc_security_group_ids = [aws_security_group.rke2_common.id]

  # Use specified private IP if provided
  private_ip                  = (each.value.config.private_ips != null && length(each.value.config.private_ips) > each.value.node_idx) ? each.value.config.private_ips[each.value.node_idx] : null
  associate_public_ip_address = each.value.config.associate_public_ip_address != null ? each.value.config.associate_public_ip_address : false


  key_name             = var.key_name
  iam_instance_profile = local.instance_profile_name != null ? local.instance_profile_name : null

  root_block_device {
    volume_size = each.value.config.root_volume_size
    volume_type = each.value.config.root_volume_type
    encrypted   = true
    tags        = merge(local.common_tags, { "Name" = "${var.cluster_name}-cpu-worker-${each.value.group_idx}-${each.value.node_idx + 1}-root" })
  }

  tags = merge(
    local.common_tags,
    {
      Name          = "${var.cluster_name}-cpu-worker-${each.value.group_idx}-${each.value.node_idx + 1}",
      "NodeType"    = "worker",
      "WorkerType"  = "cpu",
      "WorkerGroup" = each.value.group_idx
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }
}

# ###################
# # GPU Worker Nodes
# ###################
# resource "aws_instance" "gpu_worker" {
#   for_each = {
#     for node in local.gpu_worker_nodes : node.key => node
#   }

#   ami           = each.value.config.ami_id != null ? each.value.config.ami_id : local.default_ami
#   instance_type = each.value.config.instance_type

#   subnet_id = element(
#     each.value.config.subnet_ids != null ? each.value.config.subnet_ids : local.subnet_ids,
#     each.value.node_idx % length(each.value.config.subnet_ids != null ? each.value.config.subnet_ids : local.subnet_ids)
#   )

#   vpc_security_group_ids = [aws_security_group.rke2_common.id]

#   # Use specified private IP if provided
#   private_ip                  = (each.value.config.private_ips != null && length(each.value.config.private_ips) > each.value.node_idx) ? each.value.config.private_ips[each.value.node_idx] : null
#   associate_public_ip_address = each.value.config.associate_public_ip_address != null ? each.value.config.associate_public_ip_address : false


#   key_name             = var.key_name
#   iam_instance_profile = local.instance_profile_name != null ? local.instance_profile_name : null

#   root_block_device {
#     volume_size = each.value.config.root_volume_size
#     volume_type = each.value.config.root_volume_type
#     encrypted   = true
#     tags        = merge(local.common_tags, { "Name" = "${var.cluster_name}-gpu-worker-${each.value.group_idx}-${each.value.node_idx + 1}-root" })
#   }

#   tags = merge(
#     local.common_tags,
#     {
#       Name          = "${var.cluster_name}-gpu-worker-${each.value.group_idx}-${each.value.node_idx + 1}",
#       "NodeType"    = "worker",
#       "WorkerType"  = "gpu",
#       "WorkerGroup" = each.value.group_idx
#     }
#   )

#   lifecycle {
#     ignore_changes = [ami]
#   }
# }

###################
# Server Nodes
###################
resource "aws_instance" "server" {
  for_each = {
    for node in local.server_nodes : node.key => node
  }

  ami           = each.value.config.ami_id != null ? each.value.config.ami_id : local.default_ami
  instance_type = each.value.config.instance_type

  subnet_id = element(
    each.value.config.subnet_ids != null ? each.value.config.subnet_ids : local.subnet_ids,
    each.value.node_idx % length(each.value.config.subnet_ids != null ? each.value.config.subnet_ids : local.subnet_ids)
  )

  vpc_security_group_ids = [aws_security_group.rke2_common.id]

  # Use specified private IP if provided
  private_ip = (each.value.config.private_ips != null && length(each.value.config.private_ips) > each.value.node_idx) ? each.value.config.private_ips[each.value.node_idx] : null

  key_name                    = var.key_name
  iam_instance_profile        = local.instance_profile_name != null ? local.instance_profile_name : null
  associate_public_ip_address = each.value.config.associate_public_ip_address != null ? each.value.config.associate_public_ip_address : false

  root_block_device {
    volume_size = each.value.config.root_volume_size
    volume_type = each.value.config.root_volume_type
    encrypted   = true
    tags        = merge(local.common_tags, { "Name" = "${var.cluster_name}-server-${each.value.group_idx}-${each.value.node_idx + 1}-root" })
  }

  tags = merge(
    local.common_tags,
    {
      Name          = "${var.cluster_name}-server-${each.value.group_idx}-${each.value.node_idx + 1}",
      "NodeType"    = "server",
      "ServerGroup" = each.value.group_idx
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }
}


resource "null_resource" "external_destroyer" {
  triggers = var.karpenter_nodes_tags

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      filters=""
%{ for key, value in self.triggers ~}
      filters="$filters Name=tag:${key},Values=${value}"
%{ endfor ~}
      filters="$filters Name=instance-state-name,Values=running,stopped,pending"

      instance_ids=$(aws ec2 describe-instances \
        --filters $filters \
        --query "Reservations[].Instances[].InstanceId" \
        --output text)

      if [ -n "$instance_ids" ]; then
        echo "Terminating instances: $instance_ids"
        aws ec2 terminate-instances --instance-ids $instance_ids
      else
        echo "No matching instances found."
      fi
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
