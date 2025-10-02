# gpu_nodes.tf - GPU worker node resources for RKE2 cluster

###################
# GPU Worker Nodes (On-Demand)
###################
resource "aws_instance" "gpu_worker" {
  for_each = {
    for node in local.gpu_worker_nodes : node.key => node
    if node.config.use_spot_instances != true
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
    tags        = merge(local.common_tags, { "Name" = "${var.cluster_name}-gpu-worker-${each.value.group_idx}-${each.value.node_idx + 1}-root" })
  }

  tags = merge(
    local.common_tags,
    {
      Name          = "${var.cluster_name}-gpu-worker-${each.value.group_idx}-${each.value.node_idx + 1}",
      "NodeType"    = "worker",
      "WorkerType"  = "gpu",
      "WorkerGroup" = each.value.group_idx
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }
}

###################
# GPU Worker Nodes as Spot Instances
###################
resource "aws_spot_instance_request" "gpu_worker_spot" {
  for_each = {
    for node in local.gpu_worker_nodes : node.key => node
    if node.config.use_spot_instances == true
  }

  ami                    = each.value.config.ami_id != null ? each.value.config.ami_id : local.default_ami
  instance_type          = each.value.config.instance_type
  spot_price             = each.value.config.spot_price
  wait_for_fulfillment   = each.value.config.spot_wait_for_fulfillment != null ? each.value.config.spot_wait_for_fulfillment : true
  spot_type              = each.value.config.spot_type != null ? each.value.config.spot_type : "persistent"
  instance_interruption_behavior = each.value.config.spot_instance_interruption_behavior != null ? each.value.config.spot_instance_interruption_behavior : "terminate"

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
  }

  # Store node information directly in tags
  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-gpu-worker-spot-${each.value.group_idx}-${each.value.node_idx + 1}",
      NodeType = "worker",
      WorkerType = "gpu",
      WorkerGroup = tostring(each.value.group_idx),
      ClusterName = var.cluster_name
    }
  )

}
# These resources tag the actual EC2 instances created by the spot requests

# Add this to gpu_nodes.tf

# Null resource to check that GPU worker spot instances are ready
resource "null_resource" "check_gpu_worker_spot_instances" {
  for_each = aws_spot_instance_request.gpu_worker_spot
  
  triggers = {
    spot_instance_id = each.value.spot_instance_id
  }

  # This will only succeed once the spot instance is fulfilled
  provisioner "local-exec" {
    command = "aws ec2 wait instance-exists --instance-ids ${each.value.spot_instance_id}"
  }

  depends_on = [aws_spot_instance_request.gpu_worker_spot]
}

# Name tag
resource "aws_ec2_tag" "gpu_worker_spot_name_tag" {
  for_each = aws_spot_instance_request.gpu_worker_spot
  
  resource_id = each.value.spot_instance_id
  key         = "Name"
  value       = "${var.cluster_name}-gpu-worker-spot-${each.key}"
  
  depends_on = [null_resource.check_gpu_worker_spot_instances]
}

# NodeType tag
resource "aws_ec2_tag" "gpu_worker_spot_node_type_tag" {
  for_each = aws_spot_instance_request.gpu_worker_spot
  
  resource_id = each.value.spot_instance_id
  key         = "NodeType"
  value       = "worker"
  
  depends_on = [null_resource.check_gpu_worker_spot_instances]
}

# Additional tags as needed...