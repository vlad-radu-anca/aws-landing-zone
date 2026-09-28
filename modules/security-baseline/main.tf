# Runs in the management account. It registers the Security account as delegated
# administrator for each service and turns on organization-wide auto-enrolment,
# so new accounts are covered the moment they join rather than by a later sweep.
#
# The detailed configuration of each service (standards, suppression rules,
# findings routing) belongs in the Security account itself, behind an aliased
# provider, and is deliberately not done here.

########################################
# GuardDuty
########################################

resource "aws_guardduty_organization_admin_account" "this" {
  count = var.guardduty.enabled ? 1 : 0

  admin_account_id = var.security_account_id
}

########################################
# Security Hub
########################################

resource "aws_securityhub_organization_admin_account" "this" {
  count = var.securityhub.enabled ? 1 : 0

  admin_account_id = var.security_account_id
}

########################################
# Organization-wide CloudTrail
########################################

# A single organization trail covers every account, including accounts created
# later, and member accounts cannot switch it off because the SCP denies it.
resource "aws_cloudtrail" "organization" {
  count = var.cloudtrail.enabled ? 1 : 0

  name           = var.cloudtrail.name
  s3_bucket_name = var.cloudtrail.s3_bucket_name
  s3_key_prefix  = var.cloudtrail.s3_key_prefix

  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = var.cloudtrail.kms_key_arn

  cloud_watch_logs_group_arn = var.cloudtrail.cloudwatch_log_group_arn
  cloud_watch_logs_role_arn  = var.cloudtrail.cloudwatch_role_arn

  dynamic "advanced_event_selector" {
    for_each = var.cloudtrail.log_data_events ? [1] : []
    content {
      name = "Log S3 object-level and Lambda invoke events"

      field_selector {
        field  = "eventCategory"
        equals = ["Data"]
      }
    }
  }

  tags = var.tags
}

########################################
# Organization-wide Access Analyzer
########################################

# Scoped to the organization, so it reports any resource shared outside it.
resource "aws_accessanalyzer_analyzer" "organization" {
  count = var.access_analyzer.enabled ? 1 : 0

  analyzer_name = var.access_analyzer.name
  type          = "ORGANIZATION"

  tags = var.tags
}
