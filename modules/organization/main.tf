# The organization itself. ALL features (rather than consolidated billing only)
# is required for service control policies to work at all.
resource "aws_organizations_organization" "this" {
  count = var.create_organization ? 1 : 0

  feature_set = "ALL"

  enabled_policy_types = var.enabled_policy_types

  # Services that need organization-wide trusted access before a delegated
  # administrator can be registered for them.
  aws_service_access_principals = var.service_access_principals
}

data "aws_organizations_organization" "this" {
  depends_on = [aws_organizations_organization.this]
}

locals {
  root_id = data.aws_organizations_organization.this.roots[0].id

  # Flatten the two-level OU definition into a single map so each child can be
  # created with for_each and look up its parent by name.
  child_ous = merge([
    for parent, cfg in var.organizational_units : {
      for child in cfg.children : "${parent}/${child}" => {
        parent = parent
        name   = child
      }
    }
  ]...)
}

resource "aws_organizations_organizational_unit" "top" {
  for_each = var.organizational_units

  name      = each.key
  parent_id = local.root_id
  tags      = merge(var.tags, { Name = each.key })
}

resource "aws_organizations_organizational_unit" "child" {
  for_each = local.child_ous

  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.top[each.value.parent].id
  tags      = merge(var.tags, { Name = each.value.name })
}

# Registering a delegated administrator keeps security tooling out of the
# management account, which should hold as little as possible.
resource "aws_organizations_delegated_administrator" "this" {
  for_each = var.delegated_administrators

  account_id        = each.value
  service_principal = each.key
}
