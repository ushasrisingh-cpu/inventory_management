# ADR 007 Local Validation Before Cloud Deployment

**Status:** Accepted

## Context and problem

The capstone must remain reproducible without continuously running dedicated cloud resources. AI-generated artifacts also require independent validation before use.

## Decision

Validate Maven, Docker, Terraform, Kubernetes overlays, security scans, and documentation locally or in CI before cloud deployment. Use Kind or equivalent local Kubernetes for portability checks. Apply AWS only for bounded integration tests.

## Alternatives considered

- Cloud-only testing
- Static review without execution
- Manual console configuration

## Consequences and trade-offs

Local validation reduces cost and shortens feedback cycles. It cannot reproduce every managed AWS behavior, so bounded live tests remain necessary for ECS, ALB, RDS, IAM, autoscaling, S3, and recovery.

## Security implications

Earlier scanning reduces the chance of deploying insecure artifacts. Local files must remain ignored if they contain configuration values.

## Cost implications

Most validation uses local or included CI capacity. Cloud resources run only during integration testing.

## Rationale

The approach meets the guide's reproducibility requirement and demonstrates review of AI-generated work.
