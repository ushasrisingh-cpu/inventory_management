# ADR 001 AWS as the Target Cloud Platform

**Status:** Accepted

## Context and problem

The capstone required a production-inspired cloud design for a containerized Java application, managed MySQL, CI/CD identity, observability, and Infrastructure as Code.

## Decision

Use AWS in `ap-south-1`, provisioned through Terraform. Use managed services for the runtime, registry, database, secrets, logs, and archive.

## Alternatives considered

- Azure with Container Apps, ACR, and Azure Database for MySQL
- Local-only deployment with Kind or Docker Compose
- Manually created AWS resources

## Consequences and trade-offs

AWS provides consistent integration across ECS, ECR, RDS, IAM, CloudWatch, and S3. The design depends on AWS service knowledge and incurs usage charges while environments run. Terraform and local Kubernetes artifacts reduce lock-in at the engineering-process level.

## Security implications

IAM roles, OIDC, private database networking, managed secrets, encryption, and security groups replace shared credentials and unrestricted connectivity.

## Cost implications

RDS and ALB are the main dev costs. The project destroys disposable infrastructure after validation and retains only the lower-cost archive.

## Rationale

AWS was the preferred platform in the participant guide and supported the complete lifecycle with managed services and demonstrable security controls.
