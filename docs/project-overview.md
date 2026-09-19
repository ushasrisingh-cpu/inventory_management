# Inventory Management System Project Overview

## Executive summary

Acme Retail Ltd. needed a repeatable and secure engineering lifecycle for an existing Spring Boot inventory and e-checkout application. The capstone introduced Infrastructure as Code, container delivery, automated CI/CD, security scanning, managed AWS runtime services, autoscaling, operational logging, persistent archives, and tested recovery procedures.

The solution uses ECS Fargate rather than the initially proposed EKS runtime. This decision reduced operating cost and administration for a single application while retaining managed deployments, health checks, scaling, and AWS security integration. Kubernetes manifests remain in the repository for local validation and portability.

## Engineering approach

The work followed the required AI-assisted engineering sequence:

1. Analyze the business problem and repository baseline.
2. Write six AI Engineering Specifications.
3. Generate initial implementation artifacts with an AI coding assistant.
4. Review, validate, secure, and refactor every artifact.
5. Test the application, infrastructure, CI/CD, security controls, scaling, backup, and recovery.
6. Package the final documentation and presentation without including prompts or chat history.

## Delivered capabilities

- Modular Terraform for reusable AWS infrastructure
- Separate dev, production, and persistent archive environments
- Docker packaging and ECR image storage
- ECS Fargate service behind an Application Load Balancer
- Private MySQL RDS and Secrets Manager integration
- GitHub Actions CI and OIDC-based ECS delivery
- Checkov, Gitleaks, Trivy, and optional Sonar analysis
- CPU target-tracking autoscaling
- CloudWatch application and VPC flow logs
- Persistent versioned S3 storage for logs and SQL backups
- Verified SQL restore procedure
- Cost-conscious teardown that retains backup evidence

## Main outcomes

The application deployed successfully, passed readiness checks, survived load testing without failed requests, scaled out and back in as designed, produced a portable database backup, restored that backup successfully, and retained application and network logs after the dev environment was destroyed.

## Scope boundaries

The capstone did not apply the production Terraform environment. It did not configure a public HTTPS endpoint because no controlled domain was available for ACM certificate validation. Snyk, ZAP, Teams notifications, and a mandatory Sonar quality gate remain documented improvements.
