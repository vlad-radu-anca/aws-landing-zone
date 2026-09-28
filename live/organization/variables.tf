variable "region" {
  description = "Region the provider operates in. Organizations is global, but the provider still needs one."
  type        = string
  default     = "eu-central-1"
}

variable "create_organization" {
  description = "Create the organization rather than reading an existing one. Set to false when the management account already has one."
  type        = bool
  default     = false
}
