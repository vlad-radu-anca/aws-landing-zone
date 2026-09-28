output "state_bucket_name" {
  description = "Name of the state bucket, used as the `bucket` value in backend configuration."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.state.arn
}
