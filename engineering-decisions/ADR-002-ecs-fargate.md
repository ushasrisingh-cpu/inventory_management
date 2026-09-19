# ADR 002 ECS Fargate as the AWS Runtime

**Status:** Accepted, replacing the initial EKS proposal

## Context and problem

The pre-implementation specification proposed EKS. The final system deploys one Spring Boot service and needs rolling updates, health checks, logs, autoscaling, private database access, and low administrative overhead.

## Decision

Use ECS Fargate behind an Application Load Balancer. Retain Kubernetes and Kustomize artifacts for local portability and policy validation.

## Alternatives considered

- EKS with managed node groups or Fargate profiles
- EC2-hosted Docker
- Elastic Beanstalk
- App Runner

## Consequences and trade-offs

ECS reduces cluster operations and cost for a single service. The cloud runtime no longer demonstrates Kubernetes orchestration directly, but local Kind validation preserves Kubernetes engineering evidence. ECS-specific task definitions and service configuration increase AWS coupling.

## Security implications

Fargate removes host management, supports task and execution roles, integrates with Secrets Manager, and uses security-group isolation.

## Cost implications

The project avoids the EKS control-plane charge and node management. Fargate tasks, ALB, RDS, and logs remain billable while running.

## Rationale

ECS provided the required production-inspired behavior with less cost and complexity for the capstone scope.
