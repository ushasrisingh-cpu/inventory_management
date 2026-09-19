# Capstone Presentation Outline

## Presenter

Ushasri D, Group 22, Foundation Capstone

## Slide sequence

1. **Inventory Management Cloud and DevSecOps Modernization**
   Project, participant, role, and customer context.
2. **Customer problem and project objectives**
   Manual provisioning and deployment, missing standards, security validation, and documentation.
3. **Application overview**
   Spring Boot inventory features, membership, purchasing, receipts, discounts, recommendations, sales analysis, and e-checkout.
4. **AI Engineering Specifications and methodology**
   Six specifications and the analyze, generate, review, validate, and document lifecycle.
5. **AI-assisted engineering approach**
   GitHub Copilot and conversational AI use across application code, Terraform, CI/CD, containers, Kubernetes, scripts, security, and documentation.
6. **AI-assisted work verification**
   Maven, Terraform validation, Checkov, Trivy, Gitleaks, CI, AWS checks, load testing, and backup-and-restore testing.
7. **Final AWS architecture**
   ALB, ECS Fargate, RDS, Secrets Manager, ECR, CloudWatch, GitHub OIDC, and persistent S3.
8. **Infrastructure as Code**
   Terraform modules and independent development, production, and archive environments.
9. **CI pipeline**
   Maven, Gitleaks, Terraform validation, Checkov, Docker, Trivy, and conditional Sonar analysis.
10. **CD pipeline**
    Successful CI trigger, infrastructure guard, OIDC, immutable ECR tag, ECS task revision, and stability check.
11. **Security design**
    Identity, secrets, networking, scanning, encryption, documented exceptions, and the production HTTPS requirement.
12. **Autoscaling and performance evidence**
    7,507 requests with zero failures and verified one-to-two-to-one task scaling.
13. **Backup, recovery, and log archival**
    Persistent S3, successful Fargate backup, restore results, retention, and evidence after teardown.
14. **Engineering decisions and trade-offs**
    ECS instead of EKS, Kubernetes portability, independent archive state, temporary development HTTP, and manual archive operations.
15. **Results and lessons learned**
    Repeatability, automated delivery, layered security, scaling, recovery, retained evidence, and disciplined review of AI-generated artifacts.
16. **Future improvements and conclusion**
    Production HTTPS, mandatory quality gate, dynamic testing, scheduled archives, recovery drills, and centralized security monitoring.

## Demonstration sequence

1. Show the repository specification and documentation structure.
2. Show the CI jobs and a successful run.
3. Explain the CD guard while dev is offline.
4. Show the Terraform architecture and archive separation.
5. Show autoscaling and load-test evidence.
6. Show the backup object and restore evidence.
7. Show the empty dev state and retained archive objects.

Do not expose account IDs, ARNs containing sensitive context, tokens, passwords, or secret values during the demonstration.
