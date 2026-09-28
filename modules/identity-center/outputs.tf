output "instance_arn" {
  description = "ARN of the Identity Center instance."
  value       = local.instance_arn
}

output "identity_store_id" {
  description = "ID of the identity store backing the instance."
  value       = local.identity_store_id
}

output "permission_set_arns" {
  description = "Map of permission set name to ARN."
  value       = { for k, ps in aws_ssoadmin_permission_set.this : k => ps.arn }
}

output "group_ids" {
  description = "Map of group display name to group ID."
  value       = { for k, g in aws_identitystore_group.this : k => g.group_id }
}
