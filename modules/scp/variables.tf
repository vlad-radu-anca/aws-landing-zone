variable "name" {
  description = "Name of the service control policy."
  type        = string
}

variable "description" {
  description = "Description shown in the Organizations console."
  type        = string
  default     = null
}

variable "statements" {
  description = <<-EOT
  IAM policy statements that make up the policy document. Passed through to the
  rendered JSON as-is, so use the IAM casing (`Effect`, `Action`, `Resource`, `Condition`).
  Compose several guardrails into one policy rather than creating one policy per rule:
  each target can only carry five attached SCPs.
  EOT
  type        = list(any)
}

variable "target_ids" {
  description = "Roots, organizational units or account IDs the policy attaches to."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the policy."
  type        = map(string)
  default     = {}
}
