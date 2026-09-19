# Final Implementation Alignment

## Purpose

The six AI Engineering Specifications were created before implementation, as required by the capstone workflow. This document records the final engineering review, approved deviations, validation evidence, and remaining work. It preserves the original specifications while preventing planned components from being presented as completed work.

## Final platform decisions

| Specification topic | Final outcome | Status |
|---|---|---|
| AWS target cloud | AWS Mumbai region | Implemented |
| Kubernetes cloud runtime | Replaced with ECS Fargate | Approved deviation |
| Kubernetes manifests | Kustomize overlays retained for local portability and CI scanning | Implemented locally |
| Container registry | Amazon ECR with immutable commit-SHA tags | Implemented |
| Database | Private MySQL RDS with Secrets Manager | Implemented |
| CI/CD | Separate GitHub Actions CI and ECS CD workflows | Implemented |
| AWS authentication | GitHub OIDC and short-lived role credentials | Implemented |
| Infrastructure | Modular Terraform with dev, prod, and archive environments | Implemented |
| Log archive | CloudWatch events compressed and copied to persistent S3 | Implemented and tested |
| Portable database backup | One-off two-container Fargate task | Implemented and restored |
| Autoscaling | ECS CPU target tracking | Implemented and tested |

## Security-control status

**Enforced in CI:** Maven tests, Gitleaks, Terraform formatting and validation, Checkov for Terraform, Checkov for rendered Kubernetes manifests, Docker build, and Trivy blocking of fixable high and critical image findings.

**Conditional:** SonarQube or SonarCloud analysis runs only when repository configuration provides a token. The current workflow does not prove a mandatory quality gate.

**Future:** Snyk, OWASP ZAP, Microsoft Teams notifications, and mandatory Sonar quality-gate enforcement.

## Why ECS replaced EKS

ECS Fargate met the single-application runtime requirement with less operational overhead and lower capstone cost. It retained managed scheduling, rolling deployments, health checks, autoscaling, IAM integration, CloudWatch logging, and private RDS connectivity. Kubernetes artifacts remain useful for local validation and portability, but operating EKS solely for one capstone service would add cluster cost and administration without improving the demonstrated outcome.

## Validation evidence

- The ALB readiness endpoint returned HTTP 200 with status `UP`.
- ECS target tracking scaled the service from one task to two at high CPU and returned it to one after the low alarm period.
- ApacheBench completed 7,507 requests with zero failures.
- Checkov reported 185 passed, zero failed, and 29 skipped checks after documented exceptions.
- The database backup task completed with both containers exiting successfully.
- A temporary MySQL restore recovered 8 tables, 4 member records, and 8 product records.
- Application and VPC flow logs were compressed and retained in the persistent archive bucket.
- The dev environment was destroyed without deleting the independent archive.

## Specification maintenance

The original specifications remain the record of intent created before implementation. Final architecture and operations documents take precedence where this alignment record identifies an approved deviation. ADRs provide the rationale, alternatives, cost effects, and security implications for each major change.
