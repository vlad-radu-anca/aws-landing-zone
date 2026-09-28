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
