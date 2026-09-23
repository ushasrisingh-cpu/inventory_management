# Capstone presenter notes and live demo checklist

## Opening

Good morning. I am Ushasri D from Group 22. This project modernizes Acme
Retail's Spring Boot inventory management and e-checkout application into a
secure, repeatable AWS platform. My focus was not only to deploy the
application, but also to make infrastructure, delivery, security, scaling,
backup, recovery, and evidence repeatable.

## Slide-by-slide speaking notes

### 1. Title

Introduce the customer, project, and your role as Cloud and DevSecOps
Engineer. State the outcome: a cloud-ready inventory system with controlled,
automated delivery.

### 2. Customer problem and objectives

Explain the starting problems: manual provisioning, manual deployments,
inconsistent security checks, and incomplete operational documentation. The
goal was a deployable, testable platform rather than a one-time server setup.

### 3. Application overview

Briefly describe the existing business functions: inventory, members,
purchases, receipts, discounts, recommendations, sales analysis, and
e-checkout. Emphasize that the modernization preserved these capabilities.

### 4. AI specifications and methodology

State that the work followed application, infrastructure, CI/CD, security,
testing, and documentation specifications. AI-assisted output was treated as a
draft: analyze, generate, review, validate, document.

### 5. AI-assisted engineering

Explain where AI helped: Terraform structure, Docker and Kubernetes assets,
workflow ideas, scripts, documentation, and troubleshooting. Your engineering
review and the validation tools—not AI alone—decided what was accepted.

### 6. Verification of AI-assisted work

Show that generated work was checked with Maven tests, Terraform validation,
Checkov, Gitleaks, Trivy, GitHub Actions, AWS verification, load testing, and
backup-and-restore tests.

### 7. Final AWS architecture

Trace one request: user to Application Load Balancer, then ECS Fargate, then
private RDS. Secrets Manager supplies database credentials. ECR stores
immutable images, CloudWatch stores logs, and the independent S3 archive keeps
retained backup and log evidence.

### 8. Infrastructure as Code

Explain that Terraform modules define networking, IAM, ECS, RDS, ECR, and
archive capabilities. Dev is disposable; the archive has independent state so
evidence survives a dev teardown. Production is configured and validated but
was not applied to control capstone cost.

### 9. CI and Quality Gate

Walk through the pipeline: Maven test and package, Gitleaks, Terraform format
and validation, Checkov, Docker build, Trivy, and SonarCloud. State the result:
the Quality Gate passed with no new security issues or hotspots.

### 10. Approved Terraform and CD workflows

Explain the separation of responsibilities. The infrastructure workflow makes a
reviewed plan and waits for protected-environment approval before applying.
GitHub OIDC provides short-lived AWS credentials. On the first deployment it
creates the foundation, publishes an immutable image, starts ECS, and enables
autoscaling. Later CI-approved revisions use CD to update ECS.

### 11. Security design

Highlight least-privilege IAM, GitHub OIDC instead of stored cloud keys,
Secrets Manager, private RDS, security-group traffic restrictions, encryption,
and layered scans. Be clear that the dev ALB uses HTTP; a production domain,
ACM certificate, HTTPS listener, and redirect are planned before production.

### 12. Autoscaling and performance evidence

State the measured result: ApacheBench sent 7,507 requests with zero failures
at 24.76 requests per second. CPU target tracking increased the service from
one task to two under load, then returned it to one after demand fell.

### 13. Backup, recovery, and log archival

Explain that EventBridge Scheduler runs a daily Fargate database backup. The
dump is written to the protected archive bucket; backup containers exited with
code 0. The restore test recovered 8 tables, 4 members, and 8 products.
CloudWatch application and VPC flow logs can also be archived to S3.

### 14. Decisions and trade-offs

Explain the main choices: ECS Fargate provides managed containers with less
operational overhead than EKS; Kubernetes manifests remain for portability;
the archive is independent from dev; and the approval gate balances automation
with change control.

### 15. Results and lessons learned

Summarize what is proven: reproducible infrastructure, security gates,
approved deployment control, immutable images, successful health checks,
autoscaling, backup and restore, and retained evidence after environment
cleanup.

### 16. Conclusion and next steps

Close with: “The result is a secure, automated, evidence-backed foundation
that is ready to extend toward production.” Mention the next steps: domain and
HTTPS, approved OWASP ZAP testing, scheduled log archival monitoring,
production recovery drill, and centralized AWS security monitoring.

## Live demonstration order

1. Start at the repository README and point to the architecture, runbooks,
   ADRs, report, presentation, and AI specification alignment.
2. Open GitHub Actions and show one successful CI run: tests, security scans,
   and SonarCloud Quality Gate.
3. Show the Terraform infrastructure workflow: validation, reviewed plan,
   protected-environment approval, and successful apply. Explain that a plan
   does not make changes; approval is required before apply.
4. Show the successful CD run. Explain that it deploys a commit-SHA immutable
   image only after CI and infrastructure conditions are satisfied.
5. Show the ECS service result: desired 1, running 1, and completed rollout.
   Show the ALB readiness endpoint returning HTTP 200 and `UP`.
6. Show the autoscaling evidence: the service reached 2 tasks during the load
   test and returned to 1 after demand dropped.
7. Show S3 archive evidence and the backup/restore results. Do not reveal
   database credentials, tokens, secret values, or private account details.

## Questions you may be asked

**Why use three workflows?** CI proves code quality and security; Terraform
controls infrastructure through a reviewed approval gate; CD deploys approved
application images to an existing service. This separation makes failures and
responsibilities clear.

**Why is dev disposable?** It controls cost and lets the platform be recreated
from code. The archive bucket is independent, versioned, private, and retained
so logs and backup evidence are not lost when dev is destroyed.

**Why not use EKS?** ECS Fargate meets this foundation project's container
requirements while avoiding Kubernetes control-plane and node operations. The
repository still includes Kubernetes manifests for portability.

**How does autoscaling work?** ECS target tracking watches average CPU. It
adds a task when sustained CPU exceeds the 60 percent target and reduces tasks
after demand falls, within configured minimum and maximum limits.

**How are cloud credentials protected?** GitHub Actions assumes scoped AWS IAM
roles using OIDC. It receives short-lived credentials and no long-lived AWS
access key is stored in repository secrets.

## Final presenter checklist

- Rehearse for 8–10 minutes and keep the architecture explanation under two
  minutes.
- Open only the required browser tabs before presenting: repository, Actions,
  pull request checks, and AWS console or saved evidence.
- Use saved screenshots or run logs if dev has been destroyed; do not recreate
  the environment solely for the presentation unless a live demo is required.
- Never display AWS credentials, database passwords, Terraform state contents,
  secret values, or personal browser data.
- Finish by inviting questions about security, automation, scaling, or recovery.
