# ADR 003 ECR as the Container Image Registry

**Status:** Accepted

## Context and problem

CD requires a private registry that integrates with AWS identity and ECS and supports immutable deployment references.

## Decision

Use Amazon ECR. Tag deployment images with the Git commit SHA and apply a lifecycle policy to limit retained images.

## Alternatives considered

- GitHub Container Registry
- Docker Hub
- Building images directly on application hosts

## Consequences and trade-offs

ECR simplifies ECS image pulls and IAM authorization. Images remain region-specific and incur storage and transfer costs. Commit tags improve traceability and rollback.

## Security implications

The ECS execution role receives scoped pull permission, and the GitHub OIDC role receives scoped push permission. Trivy scans the image before delivery.

## Cost implications

Lifecycle retention limits storage growth. ECR cost is small relative to ALB and RDS for this workload.

## Rationale

Native ECS and IAM integration provided the simplest secure registry path.
