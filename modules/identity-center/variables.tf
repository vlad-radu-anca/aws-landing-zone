variable "permission_sets" {
  description = <<-EOT
  Permission sets keyed by name. `session_duration` is an ISO 8601 duration, for example `PT1H`.
  Prefer short sessions for administrative access. `permissions_boundary_arn` caps the effective
  permissions of the role regardless of the policies attached to it.
  EOT
  type = map(object({
    description              = optional(string)
    session_duration         = optional(string, "PT1H")
    relay_state              = optional(string)
    managed_policy_arns      = optional(list(string), [])
    inline_policy            = optional(string)
    permissions_boundary_arn = optional(string)
  }))
  default = {}
}

variable "groups" {
  description = "Identity Center groups keyed by display name. Used only when identities are managed in the Identity Center directory rather than synced from an external provider."
  type = map(object({
    description = optional(string)
  }))
  default = {}
}

variable "assignments" {
  description = "Grants of a permission set to a group across a set of accounts. Access is always granted to groups, never to individual users."
  type = list(object({
    group          = string
    permission_set = string
    account_ids    = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the permission sets."
  type        = map(string)
  default     = {}
}
