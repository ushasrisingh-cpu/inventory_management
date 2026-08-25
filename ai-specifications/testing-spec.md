# Inventory Management System Testing and Validation Specification

## 1. Existing application baseline

This testing specification is based on the current repository baseline and the application analysis already captured in the project specifications.

Known baseline facts:

- Java 11
- Maven-based build
- Spring Boot application
- project test command: `mvn test`
- application runs locally on port 8080 by default
- REST APIs can be validated using `curl`
- local/default environment can use H2
- dev/prod environments are designed for MySQL

Important baseline requirement:

- the application should pass the Java and Maven validation baseline before containerization or broader deployment testing is attempted

This means the application is expected to compile, test, and run locally before infrastructure and security testing is layered on top.

## 2. Maven validation

The project should be validated locally with Maven before moving to Docker, Kubernetes, or AWS-related testing.

### 2.1 Commands

Run the following commands locally:

- `mvn clean compile`
- `mvn test`
- `mvn package`

### 2.2 Purpose of each command

- `mvn clean compile`
  - removes previous build artifacts
  - compiles the source code
  - verifies Java source compatibility and compile integrity

- `mvn test`
  - runs the configured unit and integration tests
  - confirms the application logic and project baseline still pass

- `mvn package`
  - produces the runnable application artifact
  - validates the packaging flow for future container build processes

### 2.3 Acceptance criteria

The Maven validation is successful when all of the following are true:

- compilation succeeds
- unit and integration tests succeed according to the project configuration
- the JAR is generated successfully
- no unexpected build failures occur

## 3. Local application validation

Once the Maven build is validated, the application should be started locally with:

- `mvn spring-boot:run`

The application is expected to run on port 8080 by default unless explicitly overridden.

### 3.1 Local API validation with curl

Use curl to validate the known REST endpoints exposed by the application.

Examples:

- `curl -i http://localhost:8080/api/v1/items`
- `curl -i http://localhost:8080/api/v1/members`
- `curl -i http://localhost:8080/api/v1/fruitAndVeges`
- `curl -i http://localhost:8080/api/v1/stationary`

Do not assume that the root URL `/` is a valid application endpoint, because the application does not appear to map the root path in the controller design.

### 3.2 Expected success criteria

The local application validation passes when:

- the Spring Boot application starts successfully
- port 8080 is reachable
- the API endpoint responds with a successful HTTP status
- JSON payloads are returned as expected
- the application remains stable during the validation window

## 4. Docker validation

Docker validation is a future step after a Dockerfile is created.

### 4.1 Future local Docker workflow

Build the image locally:

- `docker build -t inventory-management:local .`

List local images:

- `docker images`

Run the container:

- `docker run -d --name inventory-local -p 8080:8080 inventory-management:local`

Validate the running container:

- `docker ps`
- `docker logs inventory-local`

Test the app from the running container:

- `curl http://localhost:8080/api/v1/items`

Stop and remove the container:

- `docker stop inventory-local`
- `docker rm inventory-local`

Optional cleanup:

- `docker rmi inventory-management:local`

### 4.2 Acceptance criteria

The Docker validation passes when:

- Docker build succeeds
- the container remains running after startup
- the application starts successfully inside the container
- the API endpoint returns expected JSON
- logs show no fatal startup errors
- no secrets are embedded in the image

## 5. CI Docker validation

In future GitHub Actions workflows, Docker validation should occur before the application proceeds to security scanning and deployment.

### 5.1 Required flow

The workflow should later perform the following sequence:

- build Docker image
- start a temporary container
- wait or retry until the application is ready
- call a known API endpoint using `curl`
- fail the workflow if the app does not start or the API check fails
- capture logs on failure
- stop and remove the temporary container after validation
- continue to security scanning only after runtime validation succeeds

### 5.2 Acceptance criteria

A CI Docker validation passes when:

- the image builds successfully
- the temporary container starts successfully
- the app becomes healthy within the retry window
- the known endpoint returns a successful response
- the temporary container is cleaned up afterward
- failures produce useful logs and clear diagnostics

## 6. Terraform validation

Terraform validation is future work and not part of the current application implementation.

### 6.1 Local validation sequence

The future Terraform workflow should use:

- `terraform fmt -check`
- `terraform init`
- `terraform validate`
- `terraform plan`

### 6.2 Notes

- real AWS provisioning is not required for every local validation cycle
- local validation helps confirm syntax, provider configuration, and execution plan viability
- this should be performed before any environment-level deployment is attempted

### 6.3 Acceptance criteria

Terraform validation passes when:

- formatting passes
- initialization succeeds
- configuration validates
- a plan can be generated when credentials/configuration are available
- no unexpected destructive changes are proposed
- no hard-coded secrets appear in the terraform source

## 7. Terraform security validation

Use Checkov for infrastructure security validation.

### 7.1 Command

- `checkov -d infrastructure/terraform`

### 7.2 Expected behavior

- scan Terraform configuration for known security issues
- report failed checks
- identify misconfigurations such as public exposure, weak permissions, or missing encryption controls
- surface issues that must be remediated or explicitly documented before deployment

### 7.3 Acceptance criteria

The infrastructure is acceptable when:

- Checkov reports no disqualifying failures
- any `High` or `Critical` configurations are remediated or intentionally accepted and documented
- no secrets are embedded in the infrastructure code

## 8. Kubernetes validation

Kubernetes validation uses local tooling such as Kind or Minikube.

### 8.1 Pre-deploy validation

Validate manifest syntax before deployment:

- `kubectl apply --dry-run=client -f kubernetes/`

This confirms the manifests can be parsed by Kubernetes without creating resources.

### 8.2 Local cluster deployment

After the manifests are ready, deploy them to a local cluster and inspect the workload.

Example commands:

- `kubectl get pods`
- `kubectl get deployments`
- `kubectl get services`
- `kubectl describe pod <pod>`
- `kubectl logs <pod>`

### 8.3 Service exposure test

Expose or forward the service locally:

- `kubectl port-forward service/<service-name> 8080:8080`

Then validate the app via curl:

- `curl http://localhost:8080/api/v1/items`

### 8.4 Acceptance criteria

Kubernetes validation passes when:

- manifests parse correctly
- Deployment is created successfully
- required replicas become Ready
- the Service routes traffic correctly
- readiness/liveness behavior functions as expected
- the application API is reachable and returns expected content

## 9. Kubernetes self-healing test

A future local Kubernetes test should verify self-healing behavior.

### 9.1 Proposed test

- identify the application pod
- delete the pod manually
- watch the Deployment recreate it
- verify the replacement pod reaches Ready state
- confirm the app remains or becomes reachable again

Example sequence:

- `kubectl get pods`
- `kubectl delete pod <pod-name>`
- `kubectl get pods -w`

### 9.2 Acceptance criteria

The self-healing validation passes when:

- the original pod is replaced
- a new pod reaches Ready state
- the application remains available or becomes available again
- no fatal startup loop is observed

## 10. Security validation

Security validation must run both locally and in CI.

### 10.1 SonarQube

Validate:

- code quality
- bugs
- vulnerabilities
- code smells
- duplication
- coverage and quality gate status

### 10.2 Snyk

Validate:

- Maven dependency vulnerabilities
- dependency risk severity
- policy outcome based on High/Critical thresholds

### 10.3 Gitleaks

Validate:

- repository secret scanning
- detection of leaked credentials
- scan results before the pipeline is allowed to proceed

### 10.4 Trivy

Validate:

- Docker image vulnerability scanning
- OS package vulnerabilities
- application dependency vulnerabilities where applicable

### 10.5 Checkov

Validate:

- Terraform configuration security
- Kubernetes manifest misconfiguration detection

### 10.6 OWASP ZAP

Validate:

- runtime security posture of the running app
- common web vulnerabilities and unsafe endpoint behavior

Do not include real tokens in documentation or local scripts.

## 11. Gitleaks remediation prerequisite

The current repository contains known hard-coded database credentials.

Before Gitleaks can be enforced as a blocking CI gate, the following must be done:

- remove credentials from source-controlled config files
- replace them with environment-variable placeholders
- store real values in approved secret management
- validate Git history implications and secret cleanup if required

This is a prerequisite for secure pipeline enforcement.

## 12. Trivy validation

Future image validation example:

- `trivy image inventory-management:local`

CI should apply the severity policy defined in the security specification:

- `CRITICAL`: block
- `HIGH`: block unless explicitly accepted and documented
- `MEDIUM`: report/review
- `LOW`: report

## 13. OWASP ZAP validation

The dynamic security validation flow should be:

- application is running
- endpoint is reachable
- ZAP baseline scan is run
- findings are recorded and reviewed
- deployment is blocked if results exceed the approved threshold

The target URL must be configurable, for example via a variable such as:

- `ZAP_TARGET_URL`

ZAP should not be treated as the primary validation against production environments.

## 14. Secrets validation

The validation process must ensure:

- no tokens or passwords are committed to Git
- no AWS credentials are embedded in repository files
- no secret values appear in Dockerfiles or image layers
- no plaintext secrets are stored in Kubernetes manifests
- GitHub Secrets are referenced by variable names only
- production secrets are retrieved through approved secret management

## 15. GitHub Actions testing responsibility

GitHub Actions will eventually automate the validation flow:

- checkout
- Java setup
- Maven compile/test/package
- SonarQube analysis
- Snyk dependency scan
- Gitleaks scan
- Docker build
- temporary Docker runtime validation
- Trivy image scan
- Terraform validation
- Checkov scan
- Kubernetes manifest validation
- deploy to a test environment where available
- OWASP ZAP security validation
- ECR push
- EKS deployment
- post-deployment health/API validation
- Teams notification

Important note:

- Copilot may generate workflow content
- GitHub Actions executes the workflow
- the engineer reviews results and resolves failures before deployment proceeds

## 16. Failure handling

If a blocking validation step fails:

- the pipeline must stop immediately
- deployment must not continue
- logs and artifacts should be retained for investigation
- Teams notification should identify the failed step when enabled

## 17. Post-deployment validation

After an EKS deployment, validate the following:

- Kubernetes rollout status
- pods are Ready
- service is reachable
- ingress or ALB is healthy
- the known API endpoint returns expected HTTP success
- application logs show no startup failure or runtime crash loop

## 18. Rollback validation

Future rollback validation should confirm the following:

- `kubectl rollout status` succeeds for the target deployment
- rollout history is available and reviewable
- `kubectl rollout undo` works when a rollback is required
- the previous stable version is reachable again

## 19. Test evidence

The following evidence should be retained after each validation pass or failure:

- Maven test result
- build result
- SonarQube quality gate result
- Snyk result
- Gitleaks result
- Trivy result
- Checkov result
- ZAP report
- Terraform validation/plan result
- Kubernetes validation output
- deployment health result
- GitHub Actions execution history

This evidence supports both operational reassurance and security review.

## 20. Definition of Done

The application and deployment are only ready for promotion when the following checklist is satisfied:

- Maven validation passes
- local application validation passes
- Docker validation passes
- CI validation pipeline passes
- Terraform validation passes when implemented
- Kubernetes validation passes in local cluster
- self-healing behavior is validated
- security scans pass according to policy
- no secrets remain in repo or manifests
- post-deployment health validation passes
- rollout and rollback validation are documented and tested
- deployment evidence is retained

## 21. Implementation note

This specification defines the required validation and testing strategy only.

It does not create workflow files, Dockerfiles, Terraform code, Kubernetes manifests, or application code changes. The purpose is to define the validation gates, commands, artifact expectations, and acceptance criteria before implementation begins.
