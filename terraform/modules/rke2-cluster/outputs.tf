# outputs.tf - Output values for RKE2 cluster module with GPU spot instances

output "cluster_name" {
  description = "Name of the RKE2 cluster"
  value       = var.cluster_name
}

output "vpc_id" {
  description = "VPC ID used for the cluster"
  value       = local.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs used for the cluster"
  value       = local.subnet_ids
}

output "master_nodes" {
  description = "Master node instances"
  value       = aws_instance.master
}

output "master_node_ids" {
  description = "IDs of master node instances"
  value       = aws_instance.master[*].id
}

output "master_private_ips" {
  description = "Private IPs of master nodes"
  value       = aws_instance.master[*].private_ip
}

output "master_public_ips" {
  description = "Public IPs of master nodes (if available)"
  value       = aws_instance.master[*].public_ip
}

output "cpu_worker_nodes" {
  description = "Map of CPU worker nodes by group and index"
  value       = aws_instance.cpu_worker
}

output "cpu_worker_private_ips" {
  description = "Private IPs of CPU worker nodes grouped by worker group"
  value = {
    for node_key, node in aws_instance.cpu_worker :
    split("-", node_key)[0] => node.private_ip...
  }
}

output "cpu_worker_public_ips" {
  description = "Public IPs of CPU worker nodes grouped by worker group (if available)"
  value = {
    for node_key, node in aws_instance.cpu_worker :
    split("-", node_key)[0] => node.public_ip...
  }
}

###################
# GPU Worker Nodes Outputs (On-demand + Spot)
###################
output "gpu_worker_nodes" {
  description = "Map of GPU worker on-demand nodes by group and index"
  value       = aws_instance.gpu_worker
}

output "gpu_worker_spot_nodes" {
  description = "Map of GPU worker spot instances by group and index"
  value       = aws_spot_instance_request.gpu_worker_spot
}

output "gpu_worker_spot_instance_ids" {
  description = "Instance IDs of GPU worker spot instances"
  value = {
    for node_key, node in aws_spot_instance_request.gpu_worker_spot :
    node_key => node.spot_instance_id
  }
}

output "gpu_worker_private_ips" {
  description = "Private IPs of GPU worker nodes (both on-demand and spot) grouped by worker group"
  value = merge(
    {
      for node_key, node in aws_instance.gpu_worker :
      split("-", node_key)[0] => node.private_ip...
    },
    {
      for node_key, node in aws_spot_instance_request.gpu_worker_spot :
      split("-", node_key)[0] => node.private_ip...
    }
  )
}

output "gpu_worker_public_ips" {
  description = "Public IPs of GPU worker nodes (both on-demand and spot) grouped by worker group (if available)"
  value = merge(
    {
      for node_key, node in aws_instance.gpu_worker :
      split("-", node_key)[0] => node.public_ip...
    },
    {
      for node_key, node in aws_spot_instance_request.gpu_worker_spot :
      split("-", node_key)[0] => node.public_ip...
    }
  )
}

output "server_nodes" {
  description = "Map of server nodes by group and index"
  value       = aws_instance.server
}

output "server_private_ips" {
  description = "Private IPs of server nodes grouped by server group"
  value = {
    for node_key, node in aws_instance.server :
    split("-", node_key)[0] => node.private_ip...
  }
}

output "server_public_ips" {
  description = "Public IPs of server nodes grouped by server group (if available)"
  value = {
    for node_key, node in aws_instance.server :
    split("-", node_key)[0] => node.public_ip...
  }
}

output "all_node_ips" {
  description = "All node IPs grouped by type"
  value = {
    master = aws_instance.master[*].private_ip
    cpu_workers = {
      for node_key, node in aws_instance.cpu_worker :
      split("-", node_key)[0] => node.private_ip...
    }
    gpu_workers = merge(
      {
        for node_key, node in aws_instance.gpu_worker :
        split("-", node_key)[0] => node.private_ip...
      },
      {
        for node_key, node in aws_spot_instance_request.gpu_worker_spot :
        split("-", node_key)[0] => node.private_ip...
      }
    )
    servers = {
      for node_key, node in aws_instance.server :
      split("-", node_key)[0] => node.private_ip...
    }
  }
}

output "all_node_public_ips" {
  description = "All node public IPs grouped by type (if available)"
  value = {
    master = aws_instance.master[*].public_ip
    cpu_workers = {
      for node_key, node in aws_instance.cpu_worker :
      split("-", node_key)[0] => node.public_ip...
    }
    gpu_workers = merge(
      {
        for node_key, node in aws_instance.gpu_worker :
        split("-", node_key)[0] => node.public_ip...
      },
      {
        for node_key, node in aws_spot_instance_request.gpu_worker_spot :
        split("-", node_key)[0] => node.public_ip...
      }
    )
    servers = {
      for node_key, node in aws_instance.server :
      split("-", node_key)[0] => node.public_ip...
    }
  }
}

output "security_groups" {
  description = "Security groups created for the cluster"
  value = {
    common = aws_security_group.rke2_common.id
    master = aws_security_group.rke2_master.id
  }
}

output "instance_profile" {
  description = "Instance profile used for cluster nodes"
  value       = local.instance_profile_name
}

output "node_counts" {
  description = "Count of nodes by type"
  value = {
    master      = length(aws_instance.master)
    cpu_workers = length(aws_instance.cpu_worker)
    gpu_workers = length(aws_instance.gpu_worker) + length(aws_spot_instance_request.gpu_worker_spot)
    servers     = length(aws_instance.server)
    total       = length(aws_instance.master) + length(aws_instance.cpu_worker) + length(aws_instance.gpu_worker) + length(aws_instance.server) +length(aws_spot_instance_request.gpu_worker_spot)
  }
}
