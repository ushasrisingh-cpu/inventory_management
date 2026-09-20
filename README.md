# Inventory Management System Cloud and DevSecOps Capstone

- **Participant:** Ushasri D
- **Group:** 22
- **Capstone level:** Foundation
- **Role:** Cloud and DevSecOps Engineer

## Project overview

This repository modernizes a Spring Boot inventory management and e-checkout application for Acme Retail Ltd. The solution replaces manual provisioning and deployment with repeatable Terraform, container delivery, GitHub Actions, layered security checks, AWS ECS Fargate, private MySQL on Amazon RDS, and persistent S3 archives.

The final design was deployed and validated in AWS Mumbai (`ap-south-1`). The disposable development environment was removed after testing, while the independent archive bucket retained database backups and exported logs.

## Business problems addressed

- Manual infrastructure provisioning
- Manual application deployments
- No Infrastructure as Code baseline
- No standard CI/CD workflow
- Weak security validation
- Incomplete operational documentation
- No defined process for reviewing AI-generated engineering artifacts

## Application capabilities

The existing application supports inventory categories, item search, members, purchase orders, receipts, discounts, sales analysis, recommendations, and e-checkout behavior. The modernization work preserves the application while improving how teams build, validate, deploy, secure, observe, back up, and remove its environments.

## Technology stack

| Area | Technology |
|---|---|
| Application | Java 17, Spring Boot, Maven |
| Database | MySQL, Amazon RDS, AWS Secrets Manager |
| Containers | Docker, Amazon ECR, ECS Fargate |
| Infrastructure | Terraform, AWS VPC, ALB, IAM, KMS, CloudWatch, S3 |
| CI/CD | GitHub Actions, AWS OIDC, immutable image tags |
| Security | Gitleaks, Trivy, Checkov, optional Sonar analysis |
| Local portability | Kubernetes manifests, Kustomize, Kind |
| Documentation | Markdown, Mermaid, ADRs, PowerPoint |

## Architecture summary

Users access the application through an internet-facing Application Load Balancer. The ALB forwards traffic to ECS Fargate tasks. Application tasks connect to MySQL RDS through restricted security-group rules and receive database credentials through Secrets Manager. Images are stored in ECR, logs are written to CloudWatch, and retained logs and portable database backups are stored in an independent versioned S3 bucket.

See [High-level architecture](architecture/high-level-architecture.md) and [AWS architecture](architecture/aws-architecture.md).

## CI and CD summary

CI runs Maven tests and packaging, uploads the JAR, scans Git history with Gitleaks, validates Terraform, scans Terraform and rendered Kubernetes manifests with Checkov, builds the Docker image, and blocks fixable high or critical findings through Trivy. Sonar analysis runs when its token is configured.

After successful CI on `master`, CD assumes an AWS role through GitHub OIDC, builds and pushes an image tagged with the commit SHA, renders a new task-definition revision, and waits for ECS service stability. The repository variable `DEV_INFRA_ENABLED` prevents deployments while the disposable dev environment is offline.

See [CI/CD flow](architecture/cicd-flow.md).

## Verified results

| Validation | Result |
|---|---|
| Application readiness | HTTP 200 and `UP` |
| ECS autoscaling | 1 task to 2 tasks under load, then back to 1 |
| Load test | 7,507 requests, 0 failures, 24.76 requests/second |
| Terraform security scan | Checkov 185 passed, 0 failed, 29 skipped |
| Database backup | Fargate dump and S3 upload containers exited with code 0 |
| Restore test | 8 tables, 4 members, and 8 products restored |
| Log archive | Application logs and VPC flow logs retained in S3 |
| Cleanup | Dev Terraform state empty after 50 resources were destroyed |

## Repository documentation

- [Automated platform operations](docs/AUTOMATED_PLATFORM_OPERATIONS.md)

- [AI specification alignment](ai-specifications/implementation-alignment.md)
- [High-level architecture](architecture/high-level-architecture.md)
- [AWS architecture](architecture/aws-architecture.md)
- [CI/CD flow](architecture/cicd-flow.md)
- [Security flow](architecture/security-flow.md)
- [Request flow](architecture/request-flow.md)
- [Project overview](docs/project-overview.md)
- [Setup](docs/setup.md)
- [Deployment](docs/deployment.md)
- [Security](docs/security.md)
- [Testing](docs/testing.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Operations](docs/operations.md)
- [Cost and cleanup](docs/cost-and-cleanup.md)
- [S3 archive and backup](docs/S3_ARCHIVE_AND_BACKUP.md)
- [Engineering decisions](engineering-decisions/README.md)
- [Presentation outline](presentation/presentation-outline.md)
- [Submission checklist](docs/submission-checklist.md)

## Local validation

```bash
mvn test
mvn package
docker build -t inventory-management:local .
terraform fmt -check -recursive infrastructure/terraform
terraform -chdir=infrastructure/terraform/environments/dev validate
```

Use environment variables or ignored local configuration for credentials. Never commit database passwords, AWS credentials, tokens, or webhook URLs.

## Known limitations

- The disposable dev ALB used HTTP because ACM requires a controlled domain for a trusted public certificate. Production should use a domain, ACM certificate, HTTPS listener, and HTTP redirect.
- Snyk, OWASP ZAP, Teams notifications, and a mandatory Sonar quality gate remain future improvements.
- Log archival and portable SQL backup scripts require manual execution. RDS automated backups remain the primary database recovery mechanism.
- Production Terraform was validated but not applied during the cost-conscious capstone exercise.

## Safe cleanup

The dev and archive stacks use independent Terraform state. Destroy the dev environment when testing ends, keep `DEV_INFRA_ENABLED=false`, and leave the archive stack running while retained evidence is required. The archive bucket uses `force_destroy = false`, versioning, public-access blocking, and lifecycle expiration.

## Repository naming check

The participant guide requires the repository name `group22-foundation`. Confirm the submission repository name with the trainer before renaming or transferring the current repository.
