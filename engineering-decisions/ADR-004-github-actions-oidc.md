# ADR 004 GitHub Actions OIDC for AWS Authentication

**Status:** Accepted

## Context and problem

The deployment workflow needs AWS access without storing long-lived access keys in GitHub.

## Decision

Configure a GitHub OIDC provider and a scoped IAM deployment role. Restrict the trust policy to the approved repository and branch.

## Alternatives considered

- IAM user access keys stored as GitHub secrets
- Manual AWS CLI deployment
- Self-hosted runner with an instance role

## Consequences and trade-offs

OIDC credentials are short-lived and require no key rotation. Trust-policy configuration must be precise, and deployment depends on GitHub's identity token service.

## Security implications

The CD job alone receives `id-token: write`. Repository and branch conditions reduce unauthorized role assumption. Permissions are scoped to delivery actions.

## Cost implications

OIDC adds no material service cost.

## Rationale

Short-lived identity removes a common credential-leak and rotation risk.
