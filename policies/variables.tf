variable "allowed_regions" {
  description = "Regions where workloads may run. Anything outside this list is denied by the region lock statement, except for global services."
  type        = list(string)
  default     = ["eu-central-1", "eu-west-1"]
}

variable "region_lock_exempt_principals" {
  description = "Principal ARN patterns exempt from the region lock, for example a break-glass role that must operate anywhere."
  type        = list(string)
  default     = ["arn:aws:iam::*:role/AWSControlTowerExecution"]
}

variable "protected_role_arns" {
  description = "Role ARN patterns that member accounts must not modify, such as the pipeline's deployment role."
  type        = list(string)
  default     = ["arn:aws:iam::*:role/platform-*"]
}

variable "platform_admin_principals" {
  description = "Principal ARN patterns allowed to bypass the platform protection statements. Keep this list short."
  type        = list(string)
  default     = ["arn:aws:iam::*:role/platform-admin"]
}

variable "sandbox_allowed_instance_types" {
  description = "EC2 instance types permitted in sandbox accounts."
  type        = list(string)
  default     = ["t3.*", "t4g.*", "m5.large", "m6g.large"]
}
