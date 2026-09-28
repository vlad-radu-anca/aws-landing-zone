variable "security_account_id" {
  description = "Account ID of the Security account, registered as delegated administrator for the security services."
  type        = string
}

variable "guardduty" {
  description = "Register the Security account as GuardDuty delegated administrator."
  type = object({
    enabled = optional(bool, true)
  })
  default = {}
}

variable "securityhub" {
  description = "Register the Security account as Security Hub delegated administrator."
  type = object({
    enabled = optional(bool, true)
  })
  default = {}
}

variable "cloudtrail" {
  description = <<-EOT
  Organization-wide CloudTrail. The S3 bucket must already exist in the log archive
  account with a policy allowing the organization to write to it. `log_data_events`
  adds S3 object-level and Lambda invoke events, which is useful but is the part of
  CloudTrail that actually costs money at volume.
  EOT
  type = object({
    enabled                  = optional(bool, false)
    name                     = optional(string, "organization-trail")
    s3_bucket_name           = optional(string)
    s3_key_prefix            = optional(string)
    kms_key_arn              = optional(string)
    cloudwatch_log_group_arn = optional(string)
    cloudwatch_role_arn      = optional(string)
    log_data_events          = optional(bool, false)
  })
  default = {}

  validation {
    condition     = !var.cloudtrail.enabled || var.cloudtrail.s3_bucket_name != null
    error_message = "cloudtrail.s3_bucket_name is required when cloudtrail.enabled is true."
  }
}

variable "access_analyzer" {
  description = "Organization-scoped IAM Access Analyzer, which reports resources shared outside the organization."
  type = object({
    enabled = optional(bool, true)
    name    = optional(string, "organization-analyzer")
  })
  default = {}
}

variable "tags" {
  description = "Tags applied to the resources created by this module."
  type        = map(string)
  default     = {}
}
