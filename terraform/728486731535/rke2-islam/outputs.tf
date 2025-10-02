# outputs.tf - Output values from the RKE2 cluster module

output "cluster_name" {
  description = "Name of the RKE2 cluster"
  value       = module.rke2_cluster.cluster_name
}

output "master_private_ips" {
  description = "Private IPs of master nodes"
  value       = module.rke2_cluster.master_private_ips
}

output "master_public_ips" {
  description = "Public IPs of master nodes (if available)"
  value       = module.rke2_cluster.master_public_ips
}

output "cpu_worker_private_ips" {
  description = "Private IPs of CPU worker nodes grouped by worker group"
  value       = module.rke2_cluster.cpu_worker_private_ips
}

output "cpu_worker_public_ips" {
  description = "Public IPs of CPU worker nodes grouped by worker group (if available)"
  value       = module.rke2_cluster.cpu_worker_public_ips
}

output "gpu_worker_private_ips" {
  description = "Private IPs of GPU worker nodes grouped by worker group"
  value       = module.rke2_cluster.gpu_worker_private_ips
}

output "gpu_worker_public_ips" {
  description = "Public IPs of GPU worker nodes grouped by worker group (if available)"
  value       = module.rke2_cluster.gpu_worker_public_ips
}

output "server_private_ips" {
  description = "Private IPs of server nodes grouped by server group"
  value       = module.rke2_cluster.server_private_ips
}

output "server_public_ips" {
  description = "Public IPs of server nodes grouped by server group (if available)"
  value       = module.rke2_cluster.server_public_ips
}

# Aggregated node information
output "all_node_ips" {
  description = "All node IPs grouped by type"
  value       = module.rke2_cluster.all_node_ips
}

output "all_node_public_ips" {
  description = "All node public IPs grouped by type (if available)"
  value       = module.rke2_cluster.all_node_public_ips
}

# Security and resource information
output "node_counts" {
  description = "Count of nodes by type"
  value       = module.rke2_cluster.node_counts
}