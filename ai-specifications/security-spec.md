# Inventory Management System Security Specification

## 1. Security objectives

This security specification defines the target security posture for the Inventory Management System, based on the application and infrastructure analysis already captured in the repository.

Primary security objectives:

- shift-left security
- fail fast during CI/CD
- least privilege for code, infrastructure, and runtime access
- no hard-coded credentials in source or configuration files
- secure container and cloud deployment
- traceable security gates with evidence retained as build and deployment artifacts
- controlled and auditable deployment flow from code to AWS EKS

Security principles:

- Security is enforced before deployment, not after.
- Sensitive values must be injected from secret stores or runtime environment variables.
- The system must fail closed when critical security checks fail.
- Every environment should have a documented policy for approvals, secrets handling, and operational review.

## 2. Source-code quality and static analysis

### 2.1 SonarQube

Use SonarQube as the required source-code quality and static analysis platform.

SonarQube must be used to measure and enforce:

- code quality
- bugs
- vulnerabilities
- code smells
- duplication
- test coverage

Required enforcement:

- The CI/CD pipeline must stop if the configured SonarQube Quality Gate fails.
- The Quality Gate should be treated as a blocking gate for merging or deployment.
- No deployment should proceed without a passing quality gate result.

Required secrets (do not include actual values):

- `SONAR_TOKEN`
- `SONAR_HOST_URL`

Recommended usage:

- run analysis in CI after checkout and build/test steps
- enforce branch and PR protections in GitHub where possible
- store token in GitHub Repository or Environment Secrets

Quality gate policy:

- no new blocker issues on the main branch
- security hotspots reviewed before merge
- code coverage considered a policy measure rather than an isolated gate unless explicitly required

## 3. Snyk

Use Snyk for dependency and software composition scanning.

### 3.1 Snyk scope

Snyk should scan for:

- open-source dependency vulnerabilities
- Maven dependency vulnerabilities
- known package issues in Java dependencies
- transitive vulnerabilities in libraries used by the application

### 3.2 Required secrets

Document the following secret name for later use:

- `SNYK_TOKEN`

Recommended storage:

- Store the token in GitHub Actions Secrets under the repository or environment-level secret store.
- Keep tokens out of YAML, scripts, or source-controlled files.

### 3.3 Severity policy

Recommended failure threshold:

- block deployment on `High` and `Critical` vulnerabilities unless explicitly accepted and documented
- `Medium` should be reviewed and tracked
- `Low` is reported and tracked, but not necessarily blocked unless a stricter internal standard requires it

### 3.4 CI/CD behavior

- Snyk should be part of the pipeline before image build or deployment.
- If the configured threshold is exceeded, the pipeline should fail and prevent promotion.

## 4. Gitleaks

Use Gitleaks to detect secrets that have been committed to the repository or are present in working files at scan time.

### 4.1 Gitleaks coverage

Gitleaks should detect:

- passwords
- API keys
- tokens
- AWS credentials
- database credentials
- SSH keys
- other secret material in source, config, or build metadata

### 4.2 Current security finding

The current application repository contains hard-coded MySQL credentials in configuration files.

This is a current security finding and should be treated as a remediation item before enforcing Gitleaks as a blocking gate for production deployment.

Required remediation path:

- remove stored credentials from source-controlled app config
- replace with environment variable placeholders or secret injection
- use GitHub Repository/Environment Secrets for CI/CD secret values
- use AWS Secrets Manager or equivalent for deployed environments
- never commit DB or AWS credentials to Git

### 4.3 Blocking policy

Once the current credential issue is remediated:

- Gitleaks should be blocking for secrets in source or generated artifacts
- any detected secret should fail the pipeline and require remediation before deployment

## 5. Trivy

Use Trivy for container and dependency vulnerability scanning.

### 5.1 Trivy coverage

Trivy should scan:

- Docker images
- OS packages inside container images
- application dependency vulnerabilities where applicable
- filesystem and config files as needed

### 5.2 Recommended blocking policy

Recommended deployment block thresholds:

- `CRITICAL`: block
- `HIGH`: block unless formally accepted and documented
- `MEDIUM`: report and review
- `LOW`: report

### 5.3 Operational use

- scan image before registry push
- scan image again before deployment to EKS
- fail the pipeline when critical/high vulnerabilities exceed policy unless a documented exception exists

## 6. Checkov

Use Checkov for Terraform and Kubernetes infrastructure scanning.

### 6.1 Scope

Checkov should validate:

- Terraform security configuration
- Kubernetes manifest security posture
- Infrastructure-as-Code misconfiguration detection
- public exposure risks
- IAM over-permissioning
- encryption settings
- security groups and network exposure
- resource limits and requests
- Kubernetes security context
- secret handling practices

### 6.2 Expected checks

Required categories for future infrastructure implementation:

- no public exposure unless explicitly required
- overly permissive security groups blocked
- encryption at rest enabled where applicable
- IAM least privilege enforcement
- Kubernetes `securityContext` checks
- `runAsNonRoot` enforced where relevant
- resource requests and limits present
- no plaintext secrets in manifests
- private networking for worker nodes and database

### 6.3 Pipeline behavior

- Checkov should be a blocking gate when policy checks fail.
- High-risk IaC misconfigurations should stop deployment progression.

## 7. OWASP ZAP

Use OWASP ZAP for dynamic application security testing after the application is running.

### 7.1 Purpose

ZAP should be used to test the runtime application for:

- insecure HTTP responses
- exposed sensitive endpoints
- missing security headers
- common web application vulnerabilities

### 7.2 Pipeline sequence

Recommended future pipeline order for DAST:

1. deploy or start test application
2. verify health endpoint or service availability
3. run ZAP baseline scan
4. review findings
5. block deployment if findings exceed the approved threshold

### 7.3 Configurability

- local or CI target URL must be configurable
- example environment variable:
  - `ZAP_TARGET_URL`
- do not hard-code the app URL in source control

## 8. Container security

Container security requirements for future image builds:

- use a minimal base image
- avoid unnecessary packages and package managers in the runtime image
- use a non-root user whenever possible
- avoid embedding secrets or environment files in the image
- pin fixed and controlled versions of base images
- scan images before pushing to ECR
- scan images again before deployment to Kubernetes
- prefer read-only filesystems where practical
- keep image layers small and well controlled

The container should not include runtime credentials or secrets inside the image filesystem.

## 9. Kubernetes security

### 9.1 Secret handling

- Kubernetes Secrets must be used for sensitive values or an external secret solution such as AWS Secrets Manager integration via workload identity or secret operator tools.
- No plaintext credentials should be committed to manifests.
- Secrets should be injected at runtime rather than stored in YAML source control.

### 9.2 Security context requirements

The workload should be configured with:

- `securityContext.runAsNonRoot: true`
- `securityContext.allowPrivilegeEscalation: false`
- limited capabilities where possible
- drop Linux privileges when supported

### 9.3 Resource controls

- define resource requests and limits
- ensure workloads do not starve other workloads in the cluster
- use sensible CPU/memory tuning once runtime load is measured

### 9.4 Health and availability

- define readiness and liveness probes
- ensure the application is self-healing and not repeatedly restarted
- align health checks with the application’s eventual actuator or equivalent endpoint

### 9.5 Least privilege and isolation

- use namespaces to isolate workloads by environment
- limit service accounts and IAM permissions
- apply network policies where appropriate
- ensure image pulls come from ECR or approved registries only

## 10. AWS security

### 10.1 IAM least privilege

- use least privilege IAM policies for all AWS automation and runtime access
- avoid long-lived static AWS keys in GitHub secrets or local developer data
- prefer short-lived session credentials via federated identities or role assumption

### 10.2 GitHub Actions to AWS authentication

- use AWS OIDC for GitHub Actions
- grant only the minimum required role for image push, deployment, or infrastructure management
- this is preferred over static AWS access keys

### 10.3 Private infrastructure

- place EKS worker nodes in private subnets
- place RDS MySQL in private subnets
- do not expose the database publicly
- enforcement must be by network design and security groups

### 10.4 Secrets Manager

- use AWS Secrets Manager for production secrets when deployed to AWS
- example secret categories:
  - database credentials
  - app-level secrets
  - TLS/certificate-related secrets

### 10.5 Encryption and data protection

- enable encryption at rest where appropriate
- ensure RDS uses encryption if required by policy
- use encrypted transport where supported

### 10.6 Security groups and logging

- restrict ingress and egress to required paths only
- ensure ALB and EKS security groups are locked down
- use CloudTrail and CloudWatch for operational evidence and security auditing

## 11. GitHub security and secrets

The future CI/CD pipeline may require the following secrets under GitHub Repository or Environment Secrets:

- `SONAR_TOKEN`
- `SONAR_HOST_URL`
- `SNYK_TOKEN`
- `AWS_ROLE_ARN`
- `AWS_REGION`
- `ECR_REPOSITORY`
- `EKS_CLUSTER_NAME`
- `TEAMS_WEBHOOK_URL` or the chosen Microsoft Teams notification secret
- optional ZAP target configuration secrets

Required handling rules:

- store secrets under GitHub Repository or Environment Secrets only
- never commit secret values into source, YAML, or scripts
- use GitHub Environments for production approvals and promotion gates
- rotate any tokens or credentials according to policy

## 12. Microsoft Teams notification security

The project will use Microsoft Teams instead of Slack.

Required notification use cases:

- deployment success
- deployment failure
- security scan failure
- quality gate failure
- critical vulnerability or DAST finding threshold breach

Security requirements:

- the webhook URL or equivalent notification endpoint must be stored as a GitHub secret
- do not expose the Teams endpoint in source control or plaintext in YAML
- keep notifications limited to relevant operational events and failure states

## 13. Security pipeline gates

Recommended CI/CD security order:

1. source checkout
2. build and unit test
3. SonarQube analysis and quality gate
4. Snyk dependency scanning
5. Gitleaks secret scanning
6. Docker image build
7. Trivy image scan
8. Checkov IaC and Kubernetes scanning
9. local or test deployment
10. health validation
11. OWASP ZAP dynamic security test
12. push image to ECR
13. deploy to EKS
14. post-deployment health check
15. Teams notification

Blocking gates:

- SonarQube Quality Gate failure should block deployment.
- Snyk high/critical threshold failure should block deployment.
- Gitleaks secret detection should block deployment after remediation is complete.
- Trivy high/critical threshold failure should block deployment unless explicitly waived.
- Checkov misconfiguration findings that fail policy should block deployment.
- OWASP ZAP findings above the defined threshold should block deployment.

## 14. Vulnerability severity policy

Recommended baseline policy:

- Critical: block
- High: block unless formally accepted and documented
- Medium: report and review
- Low: report

Exception handling:

- exceptions should be documented and approved
- exception records should include rationale, risk, expiry, and owner
- exceptions should not be silently ignored

## 15. Secret remediation for the current application

The current application source has hard-coded MySQL credentials in config files. This is a known security finding and must be remediated before the application is treated as production-ready.

Target remediation:

- remove credentials from source-controlled `application-dev.yml` and `application-prod.yml`
- use environment variable placeholders instead of literal values
- use GitHub Repository/Environment Secrets for CI/CD pipelines
- use AWS Secrets Manager or equivalent in AWS-managed environments
- use Kubernetes Secrets or external secret integration for runtime injection
- ensure that no plaintext credentials appear in Git, manifests, or image layers

This specification explicitly does not modify the application config files as part of this task.

## 16. Security evidence/artifacts

The following artifacts should be retained as evidence for auditability and operational review:

- SonarQube quality gate result
- Snyk scan report
- Gitleaks scan result
- Trivy scan result
- Checkov security scan report
- OWASP ZAP report
- GitHub Actions execution history
- deployment health results and readiness checks
- Teams notification records for major failure/success events

This becomes the evidence trail for both operational confidence and security governance.

## 17. Local security validation

Local validation can be performed without AWS deployment using the following tools and workflows:

- `mvn test` for app build and test validation
- Gitleaks locally to detect secrets in repo contents
- Snyk CLI when a valid token is available
- Trivy for local Docker image scanning
- Checkov for Terraform and Kubernetes security validation
- Docker to build and test the application image locally
- Kind or Minikube to validate Kubernetes behavior locally
- OWASP ZAP against a locally running app instance

These validations help catch problems before any AWS or production deployment is attempted.

## 18. Risks, assumptions, trade-offs

### Risks

- the application currently has no security layer and does not use a health endpoint
- config files currently contain hard-coded database secrets
- a strict security gate can slow initial iteration if not integrated into the pipeline early
- container and Kubernetes hardening may require iterative tuning of resource and security settings

### Assumptions

- the application will evolve from a prototype to a production-inspired deployment model
- CI/CD will support secure pipeline stages and secret management
- EKS, ECR, and RDS will be part of the target AWS architecture

### Trade-offs

- stronger security gates increase build time and developer friction but reduce deployment risk
- public exposure should be minimized; egress and ingress should be restricted to required paths
- stricter container and Kubernetes hardening improves resilience but requires more configuration discipline

## 19. Security acceptance criteria

The application and infrastructure are not ready for deployment until all the following are satisfied:

1. No hard-coded credentials remain in source-controlled files.
2. SonarQube Quality Gate passes and is enforced as a blocking gate.
3. Snyk scanning is configured and blocks on high/critical findings per policy.
4. Gitleaks is configured and blocks on committed secret findings.
5. Docker images are scanned by Trivy and deployment is blocked on critical/high policy violations.
6. IaC and Kubernetes config are scanned via Checkov and violations are treated as blocking.
7. Kubernetes workloads use a secure `securityContext`, non-root execution, and resource limits.
8. EKS worker nodes and RDS are in private subnets, and security groups are least-privilege.
9. AWS credentials are handled via OIDC and IAM roles instead of static keys.
10. Sensitive values are stored in GitHub secrets or AWS Secrets Manager instead of source control.
11. Local security validation is successfully run with the selected tools.
12. Deployment metadata and security scan artifacts are retained for traceability.
13. Teams notifications are configured for security and deployment events without exposing webhook values in source.

## 20. Security implementation note

This specification defines the required security engineering plan only.

It does not create any implementation files, workflow definitions, Dockerfiles, Kubernetes manifests, or Terraform code.

The goal of this document is to define the security controls, gates, and policy requirements that must be met before a secure deployment is implemented.
