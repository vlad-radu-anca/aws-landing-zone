# aws-landing-zone

A multi-account AWS landing zone built from AWS Organizations primitives with Terraform: an organizational unit tree, service control policies composed from a shared statement library, IAM Identity Center permission sets, and delegated administration for the security services. Deployed from GitHub Actions using OIDC federation, with no long-lived AWS keys anywhere.

[![Terraform](https://github.com/vlad-radu-anca/aws-landing-zone/actions/workflows/terraform.yaml/badge.svg)](https://github.com/vlad-radu-anca/aws-landing-zone/actions/workflows/terraform.yaml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

## Why not Control Tower

Control Tower is usually the right answer in a real enterprise, and [ADR 0001](docs/decisions/0001-organizations-over-control-tower.md) records that tradeoff in full. The short version: Control Tower is a managed service that owns the resources it creates, so they never enter your state, it consumes some of the five SCP attachment slots on the OUs it governs, and it turns on Config recorders everywhere, which is the line item that surprises people. Building on Organizations directly keeps everything in code and costs nothing to run.

## Layout

```
bootstrap/          S3 state bucket. Run once with local state.
policies/           Library of SCP statements, composed into documents by the caller.
modules/
  organization/     Organization, OU tree, delegated administrators.
  scp/              Renders and attaches a policy, with a size guard.
  identity-center/  Permission sets, groups, account assignments.
  security-baseline/ Delegated admins, organization trail, Access Analyzer.
live/
  organization/     The root configuration applied to the management account.
```

`live/` holds state and provider configuration. `modules/` and `policies/` hold none, so they stay reusable.

## Organizational units

```
Root
├── Security          GuardDuty, Security Hub and Access Analyzer delegated admin
├── Infrastructure    Shared networking and platform services
├── Workloads
│   ├── Prod
│   └── NonProd
├── Sandbox           Cheap, region locked, instance types capped
└── Suspended         Accounts on their way out, denied everything
```

The tree is deliberately shallow. Organizations allows five levels of nesting, but SCPs intersect as you descend, so a deep tree makes the effective permissions at a leaf hard to reason about.

## Guardrails

Service control policies are composed from statements in [`policies/`](policies/statements.tf) rather than written per policy, because **each target can carry only five attached SCPs, and each document is capped at 5,120 characters**. Those two limits bind long before the number of accounts does.

| Policy | Attached to | Statements |
| --- | --- | --- |
| `org-baseline` | Root | Deny leaving the organization, deny stopping CloudTrail, GuardDuty, Config or Security Hub |
| `identity-baseline` | Root | Deny root user activity, protect the platform roles, protect the S3 public access block |
| `workloads` | Workloads, Infrastructure | Region lock, require IMDSv2 |
| `sandbox` | Sandbox | Region lock, cap instance types |

[`modules/scp`](modules/scp/main.tf) fails at **plan** time if a document exceeds the limit, with a message pointing at the fix, rather than letting AWS reject it during apply. Every plan also reports the headroom left:

```
scp_document_sizes = {
  org-baseline      = { size = 954, remaining = 4166 }
  identity-baseline = { size = 817, remaining = 4303 }
  workloads         = { size = 616, remaining = 4504 }
  sandbox           = { size = 657, remaining = 4463 }
}
```

When a document does get close to full, the fixes in order are: merge statements, replace explicit resource lists with wildcards plus a condition, and move resource-side controls into a resource control policy, which has its own separate attachment budget.

## Access

Identity Center defines five permission sets, granted to groups and never to individual users, so joining a team is the only thing that grants access.

| Permission set | Session | For |
| --- | --- | --- |
| `Administrator` | 1 hour | Platform engineers. Short on purpose, so a forgotten session stops being useful quickly. |
| `PowerUser` | 8 hours | Day to day engineering, without IAM management |
| `ReadOnly` | 8 hours | Anyone who needs to look but not touch |
| `SecurityAudit` | 8 hours | Security review across the organization |
| `Billing` | 4 hours | Cost and usage visibility |

## Deployment

Nothing in CI holds an AWS key. GitHub mints an OIDC token that AWS trusts, exchanged for a short-lived role:

- Pull request: `fmt`, `validate` for every directory, `tflint`, `trivy`, then `plan` against a read-only role, posted as a comment.
- Merge to `main`: `apply` against a deployment role, behind a protected `landing-zone` environment so it is a reviewed step rather than automatic.

The `plan` and `apply` jobs are gated on `vars.AWS_PLAN_ROLE_ARN` and `vars.AWS_APPLY_ROLE_ARN` being set, so a fresh clone stays green without credentials.

### First run

```sh
# 1. State bucket, once, with local state
cd bootstrap && terraform init && terraform apply

# 2. Everything else
cd ../live/organization
terraform init -backend-config=backend.hcl
terraform plan
```

## Requirements

- Terraform >= 1.10, for S3 native state locking (`use_lockfile`), which removes the DynamoDB lock table older setups needed
- AWS provider ~> 6.0
- A management account with IAM Identity Center already enabled, since it cannot be turned on through the API

## Status

The organization, SCP, Identity Center and security baseline modules are written and validated in CI. Account creation is deliberately not wired up: member accounts need a unique email each and are close to irreversible once created, so the repository stops at the point where applying it would create them.

## License

[Apache-2.0](LICENSE)
