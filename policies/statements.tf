# A library of guardrail statements, grouped so callers can compose a handful of
# them into one SCP document. Organizations allows only five SCPs per target and
# 5,120 characters per document, so the unit of reuse here is the statement, not
# the policy.
#
# Sids are kept short on purpose: every character counts against the limit.

locals {
  # Actions that would let an account escape or blind the organization's controls.
  statement_protect_organization = {
    Sid    = "ProtectOrg"
    Effect = "Deny"
    Action = [
      "organizations:LeaveOrganization",
      "organizations:DeleteOrganization",
      "organizations:RemoveAccountFromOrganization",
    ]
    Resource = "*"
  }

  statement_protect_cloudtrail = {
    Sid    = "ProtectCloudTrail"
    Effect = "Deny"
    Action = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
    ]
    Resource = "*"
  }

  statement_protect_guardduty = {
    Sid    = "ProtectGuardDuty"
    Effect = "Deny"
    Action = [
      "guardduty:DeleteDetector",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:UpdateDetector",
      "guardduty:DeleteMembers",
    ]
    Resource = "*"
  }

  statement_protect_config = {
    Sid    = "ProtectConfig"
    Effect = "Deny"
    Action = [
      "config:DeleteConfigurationRecorder",
      "config:StopConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "config:DeleteConfigRule",
    ]
    Resource = "*"
  }

  statement_protect_securityhub = {
    Sid    = "ProtectSecurityHub"
    Effect = "Deny"
    Action = [
      "securityhub:DisableSecurityHub",
      "securityhub:DeleteMembers",
      "securityhub:DisassociateFromMasterAccount",
    ]
    Resource = "*"
  }

  # Deny anything outside the regions we operate in. The NotAction list carries
  # the global services that only work in us-east-1; denying those would break
  # IAM, CloudFront, Route 53 and billing everywhere.
  statement_region_restriction = {
    Sid      = "RegionLock"
    Effect   = "Deny"
    Resource = "*"
    NotAction = [
      "iam:*",
      "organizations:*",
      "route53:*",
      "cloudfront:*",
      "support:*",
      "sts:*",
      "budgets:*",
      "ce:*",
      "account:*",
      "health:*",
      "shield:*",
      "waf:*",
      "wafv2:*",
      "globalaccelerator:*",
    ]
    Condition = {
      StringNotEquals = {
        "aws:RequestedRegion" = var.allowed_regions
      }
      ArnNotLike = {
        "aws:PrincipalArn" = var.region_lock_exempt_principals
      }
    }
  }

  # The account root user should never be used for day to day work. Identity
  # Center roles are the intended path in.
  statement_deny_root_user = {
    Sid      = "DenyRoot"
    Effect   = "Deny"
    Action   = "*"
    Resource = "*"
    Condition = {
      StringLike = {
        "aws:PrincipalArn" = "arn:aws:iam::*:root"
      }
    }
  }

  # Roles created by the landing zone pipeline must not be editable from inside
  # the member account, or the guardrails become advisory.
  statement_protect_platform_roles = {
    Sid    = "ProtectPlatformRoles"
    Effect = "Deny"
    Action = [
      "iam:AttachRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePermissionsBoundary",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
    ]
    Resource = var.protected_role_arns
    Condition = {
      ArnNotLike = {
        "aws:PrincipalArn" = var.platform_admin_principals
      }
    }
  }

  # EC2 instances must use IMDSv2, which closes off the SSRF path to instance
  # credentials that IMDSv1 leaves open.
  statement_require_imdsv2 = {
    Sid      = "RequireIMDSv2"
    Effect   = "Deny"
    Action   = "ec2:RunInstances"
    Resource = "arn:aws:ec2:*:*:instance/*"
    Condition = {
      StringNotEquals = {
        "ec2:MetadataHttpTokens" = "required"
      }
    }
  }

  # Block the public-access escape hatches that most data exposures start with.
  statement_deny_public_s3 = {
    Sid    = "DenyS3PublicAccessChanges"
    Effect = "Deny"
    Action = [
      "s3:PutAccountPublicAccessBlock",
      "s3:DeleteAccountPublicAccessBlock",
    ]
    Resource = "*"
    Condition = {
      ArnNotLike = {
        "aws:PrincipalArn" = var.platform_admin_principals
      }
    }
  }

  # Sandbox accounts are for experimenting, not for running expensive hardware.
  statement_restrict_instance_types = {
    Sid      = "RestrictInstanceTypes"
    Effect   = "Deny"
    Action   = "ec2:RunInstances"
    Resource = "arn:aws:ec2:*:*:instance/*"
    Condition = {
      "ForAnyValue:StringNotLike" = {
        "ec2:InstanceType" = var.sandbox_allowed_instance_types
      }
    }
  }
}
