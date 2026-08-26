# Inventory Management System CI/CD Engineering Specification

## 1. Pipeline triggers

The repository should use GitHub Actions with the following trigger strategy:

- pull_request targeting `master`
- push to `master`

### 1.1 Pull request behavior

For pull requests:

- run CI validation and security checks
- do not deploy to AWS production
- do not publish production images to ECR
- do not mutate the EKS production environment

The PR pipeline serves as a quality gate and risk reduction mechanism before code is merged.

### 1.2 Master push behavior

For push to `master`:

- run the full CI and security validation pipeline
- if all gates pass, continue to image publication and deployment workflows
- deploy only after the required tests and scans succeed

## 2. Pipeline architecture

The workflow should use a multi-job architecture instead of a single large sequential job.

Recommended logical jobs:

- `build-test`
- `code-quality`
- `security-scan`
- `docker-build-test`
- `infrastructure-validation`
- `image-publish`
- `deploy-eks`
- `post-deployment-validation`
- `notify`

### 2.1 Job dependencies

Use `needs:` between jobs to control execution order.

Example dependency sequence:

- `build-test` must complete before `code-quality` and `security-scan`
- `security-scan` must complete before `docker-build-test`
- `docker-build-test` must complete before `image-publish`
- `image-publish` must complete before `deploy-eks`
- `deploy-eks` must complete before `post-deployment-validation`
- `notify` runs after deployment or failure events

This keeps the pipeline modular and easier to troubleshoot.

## 3. Checkout

Use the GitHub checkout action.

Requirements:

- full repository checkout
- use `fetch-depth: 0` where branch history or SonarQube metadata is required

Typical configuration:

- `actions/checkout@v4`
- `fetch-depth: 0` for coverage or historical analysis if needed

## 4. Java setup

Use Java 11, as required by the application specification.

Recommended configuration:

- Java version: 11
- Maven build environment
- dependency caching enabled when supported by the workflow implementation

The pipeline should use the project’s Maven setup instead of introducing alternate build tooling.

## 5. Maven build and tests

The CI pipeline should run the project’s standard Maven validation commands.

Example commands:

- `mvn clean compile`
- `mvn test`
- `mvn package`

### 5.1 Required behavior

The pipeline must stop if:

- compilation fails
- required tests fail
- the JAR cannot be built

The artifact produced by `mvn package` should be reproducible from the source commit and reusable for later pipeline steps.

## 6. SonarQube

SonarQube should run after the Maven build/test phase.

### 6.1 Purpose

SonarQube is used for:

- code quality
- bugs
- vulnerabilities
- code smells
- duplication
- quality gate enforcement

### 6.2 Required behavior

The pipeline must stop if the configured SonarQube Quality Gate fails.

This must be treated as a blocking gate.

### 6.3 Required configuration references

The workflow should reference:

- `${{ secrets.SONAR_TOKEN }}`
- `${{ vars.SONAR_HOST_URL }}` or a GitHub secret if preferred

Do not include real token values in the repository or specification.

## 7. Snyk

Run Snyk against the Maven dependencies in CI.

### 7.1 Purpose

Snyk should validate:

- open-source dependency vulnerabilities
- Maven dependency issues
- transitive dependency risk

### 7.2 Token usage

The workflow should use:

- `${{ secrets.SNYK_TOKEN }}`

This token must be stored in GitHub Actions Secrets, not committed to the repo.

### 7.3 Recommended policy

Recommended failure threshold:

- `Critical`: block
- `High`: block unless explicitly accepted and documented
- `Medium`: report/review
- `Low`: report

### 7.4 Placement in pipeline

Snyk should run in the security or code-quality stage before image publication and deployment.

## 8. Gitleaks

Run Gitleaks against the repository to detect secret exposure.

### 8.1 Purpose

Gitleaks is intended to detect:

- passwords
- API keys
- tokens
- AWS credentials
- database credentials
- other secret material in source or generated files

### 8.2 Current security state

The current project contains known hard-coded MySQL credentials in configuration files.

This must be remediated before Gitleaks is enforced as a strict blocking gate for production deployment.

### 8.3 Blocking behavior

After remediation:

- Gitleaks findings should fail the pipeline
- secrets must be resolved before deployment proceeds

## 9. Terraform validation

Terraform validation should be implemented when the infrastructure code exists.

### 9.1 Required local CI commands

When the Terraform implementation is present, the workflow should run:

- `terraform fmt -check`
- `terraform init`
- `terraform validate`

### 9.2 Plan execution

A `terraform plan` should only run in an appropriate environment where AWS configuration and credentials are available.

### 9.3 PR policy

`terraform apply` must not run on pull requests.

## 10. Checkov

Run Checkov against both Terraform and Kubernetes assets.

### 10.1 Scope

Checkov should validate:

- Terraform security misconfigurations
- Kubernetes manifest misconfigurations
- insecure resource definitions
- public exposure risks
- overly permissive security groups
- encryption settings
- IAM misconfigurations
- resource limits and requests
- secrets handling and manifest security

### 10.2 Blocking behavior

Security policy failures should block deployment according to the security specification.

## 11. Application packaging

The pipeline should build the executable Spring Boot JAR before the Docker image is built.

The artifact should be reproducible from the source commit and must be retained as evidence when appropriate.

## 12. Docker build

The workflow should build the Docker image after the code and security gates pass.

### 12.1 Requirements

- use the approved Dockerfile
- use an immutable image tag based on the Git commit SHA
- example concept:
  - `inventory-management:${{ github.sha }}`
- do not rely on a floating `latest` tag as the only deployment tag

### 12.2 Image publication rule

The image should only be published after runtime validation succeeds.

## 13. Docker local/runtime validation in GitHub Actions

After the Docker image is built, the workflow should validate that the application starts correctly inside a temporary container.

### 13.1 Required runtime validation flow

The workflow should:

- start a temporary Docker container
- map the application port
- wait or retry until the app becomes ready
- call a known REST API endpoint such as `/api/v1/items`
- validate that the HTTP response is successful
- capture container logs if validation fails
- stop and remove the temporary container after the test

### 13.2 Required behavior

The workflow must not publish or deploy the image if runtime validation fails.

## 14. Trivy

Run Trivy against the built Docker image before publication.

### 14.1 Use severity rules from the security specification

Recommended policy:

- `CRITICAL`: block
- `HIGH`: block unless explicitly accepted and documented
- `MEDIUM`: report/review
- `LOW`: report

### 14.2 Pipeline placement

Trivy should run after local Docker runtime validation and before image publication or deployment.

## 15. OWASP ZAP

OWASP ZAP should run only after a running application instance is available.

### 15.1 Recommended CI strategy

- run a validated Docker container or test deployment
- verify the app endpoint is reachable
- run a ZAP baseline scan
- save and review the report
- apply the severity threshold defined in the security specification

### 15.2 Important note

The target URL must be configurable. Do not require a production URL as the primary CI test.

## 16. AWS authentication

The workflow should use GitHub Actions OIDC to access AWS.

### 16.1 Required authentication model

- do not use long-lived AWS access keys
- use AWS OIDC federation
- grant only the required permissions to the GitHub Actions role

### 16.2 Workflow permissions

The workflow should define:

- `id-token: write`
- `contents: read`

These permissions are required for secure OIDC-based role assumption.

### 16.3 Role reference

The workflow should reference an IAM role using:

- `${{ vars.AWS_ROLE_ARN }}`

The trust relationship for the role must restrict access to the approved repository, branch, and environment.

## 17. GitHub configuration

The workflow should use a combination of GitHub Secrets and Variables.

### 17.1 GitHub Secrets

Required secret values for future implementation:

- `SONAR_TOKEN`
- `SNYK_TOKEN`
- `TEAMS_WEBHOOK_URL` or another approved Teams notification credential

### 17.2 GitHub Variables

Required non-secret configuration values:

- `SONAR_HOST_URL`
- `AWS_ROLE_ARN`
- `AWS_REGION`
- `ECR_REPOSITORY`
- `EKS_CLUSTER_NAME`

### 17.3 Distinction

- Secrets are for sensitive values
- Variables are for non-sensitive configuration

## 18. ECR authentication and image publishing

After all required CI and security gates pass:

- authenticate to AWS using OIDC
- login to Amazon ECR
- tag the image using the immutable commit SHA
- push the tagged image to ECR

The project should not use S3 for Docker image storage. ECR is the correct registry.

## 19. EKS deployment

This deploy step should run only on `push` to `master`.

### 19.1 Required tasks

- configure `kubectl` for the target EKS cluster
- deploy or update Kubernetes resources
- update the Deployment to the immutable ECR image
- wait for rollout completion

### 19.2 Required command

Use:

- `kubectl rollout status`

Deployment must fail if the rollout does not complete successfully.

## 20. Kubernetes deployment strategy

Use rolling updates.

Required deployment characteristics:

- minimum replicas per the infrastructure specification
- readiness probe
- liveness probe
- resource requests and limits
- self-healing behavior
- future rollback support

These details should align with the infrastructure and testing specifications.

## 21. Post-deployment validation

After EKS rollout, the workflow should validate the running application.

### 21.1 Required checks

- verify pods are Ready
- verify service or ingress is reachable
- verify ALB target health where available
- call a known API endpoint such as `/api/v1/items`
- verify expected HTTP response

### 21.2 Important note

Do not rely on the root URL `/` because the application does not expose a root endpoint as part of the known controller design.

## 22. Microsoft Teams notification

The project uses Microsoft Teams instead of Slack.

### 22.1 Notification events

Use Teams notifications for:

- successful deployment
- failed deployment
- security-gate failure
- workflow failure when useful

### 22.2 Credential handling

- store the webhook URL in GitHub Secrets
- do not commit the actual Teams endpoint into the repository
- include useful context such as repository, branch, commit SHA, environment, and stage status

## 23. Environments

Recommend a GitHub Environment named:

- `production`

Deployment jobs should use the environment.

Where supported, use:

- required reviewers
- branch restrictions
- environment-specific secrets and variables

## 24. Pull request behavior

The PR pipeline should perform:

- checkout
- build
- tests
- SonarQube
- Snyk
- Gitleaks
- Terraform validation
- Checkov
- Docker build
- local Docker runtime validation
- Trivy
- optional ZAP test

### 24.1 PR restrictions

A pull request pipeline must not:

- push production images to ECR
- deploy to EKS
- modify production infrastructure

## 25. Master push behavior

On push to `master`, the pipeline should:

- run all CI and security gates
- publish the image to ECR
- deploy or update EKS
- validate rollout and application health
- send Teams notification

## 26. Failure behavior

If any mandatory stage fails:

- downstream deployment jobs must not run
- logs and reports should remain available
- the workflow status should be failure
- notifications should identify the failed stage when possible

## 27. Artifacts and reports

The workflow should retain or publish the following evidence:

- Maven test reports
- SonarQube results
- Snyk scan results
- Gitleaks results
- Trivy results
- Checkov results
- ZAP results
- Terraform validation results
- deployment status and health evidence

These artifacts allow traceability for both engineering and security review.

## 28. Security of GitHub Actions

Best practices for the workflow include:

- pin reviewed third-party actions to approved versions or commit SHAs
- use least-privilege workflow permissions
- never echo secrets into logs
- avoid untrusted script execution using secrets on pull requests
- separate PR validation from deployment logic
- use OIDC for AWS access
- use environment protection for production deployment approvals

## 29. Workflow file structure

The future implementation should likely live under:

- `.github/workflows/`

Recommended file structures:

- `ci.yml`
- `cd.yml`

or a single combined workflow such as:

- `ci-cd.yml`

### 29.1 Preferred structure for this project

For a foundation capstone, a small number of clearly separated workflows is usually easier to understand and maintain than a highly fragmented design.

Recommended approach:

- keep `ci.yml` for PR validation and core checks
- keep `cd.yml` for master-only deployment and publishing

This separation keeps review and failure analysis simpler while preserving the required controls.

## 30. Definition of Done

The CI/CD pipeline is only considered complete when the following is true:

- pull requests run validation and security checks without deploying
- master pushes run the full pipeline and deployment path
- code builds and tests successfully
- SonarQube Quality Gate passes
- Snyk vulnerabilities are treated according to policy
- Gitleaks secret scanning passes after remediation
- Docker image builds and runtime validation succeeds
- Trivy scan meets policy thresholds
- Terraform validation passes when implemented
- Checkov passes the required IaC/Kubernetes checks
- ZAP validates a running app instance without exposing production endpoints
- ECR image publication succeeds only after runtime validation
- EKS deployment succeeds with rollout completion and post-deploy validation
- Teams notifications fire for success/failure events
- deployment artifacts and logs are retained for evidence

## 31. Implementation note

This specification defines the required CI/CD design only.

It does not create workflow files, Dockerfiles, Terraform files, Kubernetes manifests, or application code changes. The purpose is to define the deployment pipeline structure, security gates, artifact handling, and rollout behavior required before implementation begins.
