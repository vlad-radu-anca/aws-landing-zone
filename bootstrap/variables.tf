variable "region" {
  description = "Region the state bucket is created in."
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state. Must be globally unique."
  type        = string
  default     = "asgard-landing-zone-tfstate"
}

variable "kms_key_arn" {
  description = "KMS key for state encryption. Null uses SSE-S3, which is sufficient unless you need key separation."
  type        = string
  default     = null
}

variable "noncurrent_version_retention_days" {
  description = "How long superseded state versions are kept before expiry."
  type        = number
  default     = 90
}
