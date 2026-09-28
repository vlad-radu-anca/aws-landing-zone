locals {
  document = jsonencode({
    Version   = "2012-10-17"
    Statement = var.statements
  })

  # AWS Organizations caps an SCP document at 5,120 characters. At scale this,
  # and the five-attachments-per-target limit, are what bind first, not the
  # number of accounts. Surfacing the size lets callers see how much room is left.
  size_limit     = 5120
  document_size  = length(local.document)
  size_remaining = local.size_limit - local.document_size
}

resource "aws_organizations_policy" "this" {
  name        = var.name
  description = var.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = local.document
  tags        = var.tags

  lifecycle {
    # Fail at plan time rather than getting a MalformedPolicyDocument at apply.
    precondition {
      condition     = local.document_size <= local.size_limit
      error_message = "SCP '${var.name}' renders to ${local.document_size} characters, over the ${local.size_limit} limit. Merge statements, replace resource lists with wildcards plus conditions, or split across another attachment slot."
    }

    precondition {
      condition     = length(var.statements) > 0
      error_message = "SCP '${var.name}' has no statements."
    }
  }
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = toset(var.target_ids)

  policy_id = aws_organizations_policy.this.id
  target_id = each.value
}
