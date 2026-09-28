variable "create_organization" {
  description = "Create the organization. Set to false when the account is already the management account of an existing organization, in which case it is only read."
  type        = bool
  default     = true
}

variable "enabled_policy_types" {
  description = "Organization policy types to enable on the root. Service control policies must be enabled before any SCP can be attached."
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]
}

variable "service_access_principals" {
  description = "Service principals granted trusted access to the organization. Required before registering a delegated administrator for those services."
  type        = list(string)
  default = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
    "account.amazonaws.com",
  ]
}

variable "organizational_units" {
  description = <<-EOT
  Top-level organizational units, each with optional child OUs. Keys are the OU names.
  A flat, shallow tree is deliberate: Organizations allows five levels of nesting and
  five attached SCPs per target, and SCPs intersect as you descend, so deep trees
  become hard to reason about.
  EOT
  type = map(object({
    children = optional(list(string), [])
  }))
  default = {}
}

variable "delegated_administrators" {
  description = "Delegated administrator account ID keyed by service principal, for example `guardduty.amazonaws.com` mapped to the Security account."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the organizational units."
  type        = map(string)
  default     = {}
}
