output "organization_id" {
  description = "ID of the organization."
  value       = module.organization.organization_id
}

output "root_id" {
  description = "ID of the organization root."
  value       = module.organization.root_id
}

output "organizational_unit_ids" {
  description = "Map of OU name to OU ID."
  value       = module.organization.organizational_unit_ids
}

output "scp_document_sizes" {
  description = "Rendered size of each service control policy against the 5,120 character limit, with headroom remaining."
  value = {
    for k, m in {
      org-baseline      = module.scp_org_baseline
      identity-baseline = module.scp_identity_baseline
      workloads         = module.scp_workloads
      sandbox           = module.scp_sandbox
      } : k => {
      size      = m.document_size
      remaining = m.size_remaining
    }
  }
}
