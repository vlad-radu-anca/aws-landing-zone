output "organization_id" {
  description = "ID of the organization."
  value       = data.aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "ARN of the organization."
  value       = data.aws_organizations_organization.this.arn
}

output "root_id" {
  description = "ID of the organization root, used as an SCP attachment target."
  value       = local.root_id
}

output "management_account_id" {
  description = "Account ID of the management account."
  value       = data.aws_organizations_organization.this.master_account_id
}

output "organizational_unit_ids" {
  description = "Map of OU name to OU ID, including child OUs keyed as `parent/child`."
  value = merge(
    { for k, ou in aws_organizations_organizational_unit.top : k => ou.id },
    { for k, ou in aws_organizations_organizational_unit.child : k => ou.id },
  )
}

output "organizational_unit_arns" {
  description = "Map of OU name to OU ARN."
  value = merge(
    { for k, ou in aws_organizations_organizational_unit.top : k => ou.arn },
    { for k, ou in aws_organizations_organizational_unit.child : k => ou.arn },
  )
}
