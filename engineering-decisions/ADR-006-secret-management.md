# ADR 006 Managed Secret Handling

**Status:** Accepted

## Context and problem

The application requires database credentials, while CI may require scanner tokens. Committing values or placing them in Terraform variables would expose sensitive data.

## Decision

Let RDS manage its master secret in AWS Secrets Manager. Permit the ECS execution role to retrieve only the required secret. Store optional CI tokens in GitHub Secrets and non-sensitive configuration in GitHub Variables.

## Alternatives considered

- Plaintext application properties
- Terraform-managed password values
- Environment files committed to Git
- A self-hosted secret manager

## Consequences and trade-offs

Managed secrets improve control and auditability but require IAM permissions and service integration. Local developers still need an ignored configuration method.

## Security implications

No documentation, workflow, or Terraform source contains secret values. Gitleaks provides an additional detection gate.

## Cost implications

Secrets Manager has a small recurring cost and API request cost.

## Rationale

Managed storage and scoped runtime retrieval provide a safer and more maintainable credential lifecycle.
