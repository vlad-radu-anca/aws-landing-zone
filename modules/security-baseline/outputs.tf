output "guardduty_delegated_admin_account_id" {
  description = "Account registered as GuardDuty delegated administrator, if enabled."
  value       = try(aws_guardduty_organization_admin_account.this[0].admin_account_id, null)
}

output "securityhub_delegated_admin_account_id" {
  description = "Account registered as Security Hub delegated administrator, if enabled."
  value       = try(aws_securityhub_organization_admin_account.this[0].admin_account_id, null)
}

output "cloudtrail_arn" {
  description = "ARN of the organization trail, if enabled."
  value       = try(aws_cloudtrail.organization[0].arn, null)
}

output "access_analyzer_arn" {
  description = "ARN of the organization Access Analyzer, if enabled."
  value       = try(aws_accessanalyzer_analyzer.organization[0].arn, null)
}
