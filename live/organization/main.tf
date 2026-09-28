# Landing zone root configuration, applied against the management account.
#
# The guardrails are composed from the shared statement library rather than
# written inline, because Organizations allows only five SCPs per target and
# 5,120 characters per document. Grouping related denies into one policy per
# concern keeps attachment slots free for the OUs that need them.

locals {
  project_name = "asgard"

  tags = {
    Terraform = "true"
    Project   = local.project_name
    Component = "landing-zone"
  }

  allowed_regions = ["eu-central-1", "eu-west-1"]
}

module "statements" {
  source = "../../policies"

  allowed_regions = local.allowed_regions
}

module "organization" {
  source = "../../modules/organization"

  # The organization already exists in most real accounts; flip this on for a
  # greenfield management account.
  create_organization = var.create_organization

  organizational_units = {
    Security       = {}
    Infrastructure = {}
    Workloads      = { children = ["Prod", "NonProd"] }
    Sandbox        = {}
    Suspended      = {}
  }

  tags = local.tags
}

########################################
# Guardrails attached to every account
########################################

module "scp_org_baseline" {
  source = "../../modules/scp"

  name        = "${local.project_name}-org-baseline"
  description = "Protects the organization, its audit trail and its security services"

  statements = [
    module.statements.protect_organization,
    module.statements.protect_cloudtrail,
    module.statements.protect_guardduty,
    module.statements.protect_config,
    module.statements.protect_securityhub,
  ]

  # Attached at the root, so it applies to every account including future ones.
  target_ids = [module.organization.root_id]
  tags       = local.tags
}

module "scp_identity_baseline" {
  source = "../../modules/scp"

  name        = "${local.project_name}-identity-baseline"
  description = "Denies root user activity and protects the platform roles"

  statements = [
    module.statements.deny_root_user,
    module.statements.protect_platform_roles,
    module.statements.deny_public_s3,
  ]

  target_ids = [module.organization.root_id]
  tags       = local.tags
}

########################################
# Guardrails per organizational unit
########################################

module "scp_workloads" {
  source = "../../modules/scp"

  name        = "${local.project_name}-workloads"
  description = "Region lock and IMDSv2 requirement for workload accounts"

  statements = [
    module.statements.region_restriction,
    module.statements.require_imdsv2,
  ]

  target_ids = [
    module.organization.organizational_unit_ids["Workloads"],
    module.organization.organizational_unit_ids["Infrastructure"],
  ]
  tags = local.tags
}

module "scp_sandbox" {
  source = "../../modules/scp"

  name        = "${local.project_name}-sandbox"
  description = "Keeps sandbox accounts cheap and inside the approved regions"

  statements = [
    module.statements.region_restriction,
    module.statements.restrict_instance_types,
  ]

  target_ids = [module.organization.organizational_unit_ids["Sandbox"]]
  tags       = local.tags
}

########################################
# Identity Center
########################################

module "identity_center" {
  source = "../../modules/identity-center"

  permission_sets = {
    ReadOnly = {
      description         = "Read-only access for everyone who needs to look but not touch"
      session_duration    = "PT8H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }

    PowerUser = {
      description         = "Day to day engineering access, without IAM management"
      session_duration    = "PT8H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }

    # Administrative access is deliberately short-lived: one hour, so a forgotten
    # session stops being useful quickly.
    Administrator = {
      description         = "Full administrative access, for platform engineers"
      session_duration    = "PT1H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }

    SecurityAudit = {
      description      = "Security review access across the organization"
      session_duration = "PT8H"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/SecurityAudit",
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
      ]
    }

    Billing = {
      description         = "Cost and billing visibility, nothing else"
      session_duration    = "PT4H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/job-function/Billing"]
    }
  }

  groups = {
    platform-engineers = { description = "Owns the landing zone and shared infrastructure" }
    developers         = { description = "Builds and runs workloads" }
    security           = { description = "Reviews findings and audits configuration" }
    finance            = { description = "Reviews cost and usage" }
  }

  # Assignments are commented out until real account IDs exist. The structure is
  # what matters here: access is granted to groups, never to individual users.
  # assignments = [
  #   {
  #     group          = "platform-engineers"
  #     permission_set = "Administrator"
  #     account_ids    = [var.security_account_id, var.log_archive_account_id]
  #   },
  #   {
  #     group          = "developers"
  #     permission_set = "PowerUser"
  #     account_ids    = [var.sandbox_account_id]
  #   },
  # ]

  tags = local.tags
}

########################################
# Security services
########################################

module "security_baseline" {
  source = "../../modules/security-baseline"

  count = var.security_account_id == null ? 0 : 1

  security_account_id = var.security_account_id

  # The organization trail needs a bucket in the log archive account, so it stays
  # off until those accounts exist.
  cloudtrail = {
    enabled = false
  }

  tags = local.tags
}
