# Identity Center must already be enabled in the management account; it cannot
# be turned on through the API. Everything below configures an existing instance.
data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  # Flatten permission set to managed policy pairs so each attachment is its own
  # resource rather than a list that reorders.
  managed_policy_attachments = merge([
    for ps_name, ps in var.permission_sets : {
      for arn in ps.managed_policy_arns : "${ps_name}/${basename(arn)}" => {
        permission_set = ps_name
        policy_arn     = arn
      }
    }
  ]...)

  # One assignment per group, per account, per permission set.
  assignments = merge([
    for a in var.assignments : {
      for account_id in a.account_ids :
      "${a.group}/${a.permission_set}/${account_id}" => {
        group          = a.group
        permission_set = a.permission_set
        account_id     = account_id
      }
    }
  ]...)
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = var.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = local.instance_arn
  session_duration = each.value.session_duration
  relay_state      = each.value.relay_state
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.managed_policy_attachments

  instance_arn       = local.instance_arn
  managed_policy_arn = each.value.policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each = { for k, ps in var.permission_sets : k => ps if ps.inline_policy != null }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  inline_policy      = each.value.inline_policy
}

# A permissions boundary on a permission set caps what the resulting role can do
# even if someone attaches a broader policy to it later.
resource "aws_ssoadmin_permissions_boundary_attachment" "this" {
  for_each = { for k, ps in var.permission_sets : k => ps if ps.permissions_boundary_arn != null }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn

  permissions_boundary {
    managed_policy_arn = each.value.permissions_boundary_arn
  }
}

resource "aws_identitystore_group" "this" {
  for_each = var.groups

  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value.description
}

# Access is granted to groups, never to individual users, so joining a team is
# the only thing that grants access.
resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.assignments

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn

  principal_id   = aws_identitystore_group.this[each.value.group].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
