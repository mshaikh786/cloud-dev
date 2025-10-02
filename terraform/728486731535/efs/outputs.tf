output "efs_id" {
  description = "The ID of the EFS file system"
  value       = module.efs-storage-class.id
}

output "efs_dns_name" {
  description = "The DNS name of the EFS file system"
  value       = module.efs-storage-class.dns_name
}

output "efs_mount_targets" {
  description = "The mount target IDs of the EFS file system"
  value       = module.efs-storage-class.mount_targets
}