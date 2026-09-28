output "protect_organization" {
  description = "Denies leaving or dismantling the organization."
  value       = local.statement_protect_organization
}

output "protect_cloudtrail" {
  description = "Denies stopping, deleting or altering CloudTrail trails."
  value       = local.statement_protect_cloudtrail
}

output "protect_guardduty" {
  description = "Denies disabling GuardDuty or detaching from the delegated administrator."
  value       = local.statement_protect_guardduty
}

output "protect_config" {
  description = "Denies stopping or deleting AWS Config recorders, channels and rules."
  value       = local.statement_protect_config
}

output "protect_securityhub" {
  description = "Denies disabling Security Hub or detaching from the delegated administrator."
  value       = local.statement_protect_securityhub
}

output "region_restriction" {
  description = "Denies actions outside the allowed regions, exempting global services."
  value       = local.statement_region_restriction
}

output "deny_root_user" {
  description = "Denies all actions performed by an account root user."
  value       = local.statement_deny_root_user
}

output "protect_platform_roles" {
  description = "Denies modification of the roles the landing zone pipeline relies on."
  value       = local.statement_protect_platform_roles
}

output "require_imdsv2" {
  description = "Denies launching EC2 instances that do not require IMDSv2."
  value       = local.statement_require_imdsv2
}

output "deny_public_s3" {
  description = "Denies changes to the account-level S3 public access block."
  value       = local.statement_deny_public_s3
}

output "restrict_instance_types" {
  description = "Denies EC2 instance types outside the sandbox allow list."
  value       = local.statement_restrict_instance_types
}
