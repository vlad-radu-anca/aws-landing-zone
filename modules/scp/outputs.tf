output "id" {
  description = "ID of the service control policy."
  value       = aws_organizations_policy.this.id
}

output "arn" {
  description = "ARN of the service control policy."
  value       = aws_organizations_policy.this.arn
}

output "document" {
  description = "Rendered policy document."
  value       = local.document
}

output "document_size" {
  description = "Size of the rendered document in characters, against the 5,120 limit."
  value       = local.document_size
}

output "size_remaining" {
  description = "Characters left before the policy hits the 5,120 limit. Useful for spotting policies that are close to full."
  value       = local.size_remaining
}
