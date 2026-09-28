# 1. Build on Organizations rather than Control Tower

Date: 2026-09-28

Status: accepted

## Context

A landing zone is a pattern, not a product: a multi-account AWS environment with identity, logging, guardrails and a network baseline already in place. There are four ways to get one.

**AWS Control Tower** is a managed service that sets up and governs a landing zone. It orchestrates Organizations, Service Catalog, CloudFormation StackSets, Config, CloudTrail and Identity Center, and provides Account Factory for vending accounts plus controls in three flavours: preventive (SCPs), detective (Config rules) and proactive (CloudFormation hooks).

**Landing Zone Accelerator on AWS** is a config-driven solution aimed at heavily regulated estates. It can sit on top of Control Tower and does support custom SCPs, supplied as JSON files referenced from `organization-config.yaml`.

**AWS Landing Zone**, capital L, was the earlier CloudFormation-based solution. It is deprecated and superseded by Control Tower. The name causes confusion and is worth disambiguating.

**Organizations directly**, which is what this repository does.

Terraform can drive Control Tower: `aws_controltower_landing_zone` takes a manifest and version, `aws_controltower_control` enables a guardrail on an OU, and `aws_controltower_baseline` applies baselines. So "use Control Tower" and "use Terraform" are not mutually exclusive.

## Decision

Build the landing zone from Organizations primitives with Terraform.

## Consequences

What this buys:

- **Everything is in state and in git.** With Control Tower, Terraform manages the landing zone resource but not the StackSets, Config recorders, trails and roles the service creates. Those never enter your state. The resource exposes `drift_status` as read-only for exactly this reason: you can observe drift but you repair it through Control Tower, not through `terraform apply`.
- **The full SCP attachment budget.** Organizations allows five attached SCPs per target. Control Tower's own controls consume some of those slots on the OUs it governs, and this environment needs them.
- **No mandatory cost floor.** Control Tower is free as a service but enables Config recorders across accounts and regions, which is the part that generates a real bill. Here, each service is turned on deliberately.
- **The guardrails are readable.** The SCPs live in version control as composed statements with comments explaining each one, rather than behind a console abstraction.

What it costs:

- **No Account Factory.** Account vending must be written, and is not yet.
- **No managed baseline.** Nothing updates the guardrails as AWS publishes new controls; that is now a maintenance task.
- **More to get wrong.** Control Tower encodes a lot of accumulated AWS opinion about account structure and logging that has to be reproduced deliberately here.

## When the other choice is right

For a regulated enterprise with a small platform team, Control Tower or Landing Zone Accelerator is usually the better call: the governed baseline, Account Factory and the steady stream of new controls are worth more than the flexibility given up. Hand-building makes sense when the structure needed cannot be expressed in Control Tower's model, when the SCP attachment budget is genuinely contended, or when one IaC workflow across the whole estate matters more than a managed baseline.

This repository chooses the hand-built path because its purpose is to show the primitives working, not to minimise the operational burden of running it.
