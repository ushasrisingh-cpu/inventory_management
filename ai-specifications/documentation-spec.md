# Inventory Management System Documentation Specification

## 1. Purpose

This specification defines the documentation deliverables for the Inventory Management System and e-checkout application. It describes the documentation that should accompany the application, its AWS deployment design, DevSecOps pipeline, security controls, local validation process, and operational procedures.

This is a documentation specification only. It does not authorize changes to application source code or the creation of deployment implementation files.

## 2. Documentation goals

The completed documentation set must:

- explain the existing Spring Boot inventory and e-checkout application
- provide reproducible local setup and validation instructions
- describe the target AWS, Docker, Terraform, and Kubernetes architecture
- explain the CI/CD workflow and its quality and security gates
- document secret management and identity decisions
- provide testing, troubleshooting, operations, cost, and cleanup guidance
- record significant engineering decisions with ADRs
- support a concise technical presentation and demonstration
- distinguish current repository behavior from future implementation work

Documentation must be accurate to the repository and must not claim that future infrastructure or automation already exists.

## 3. Required repository documentation structure

The intended documentation structure is:

```text
README.md
architecture/
  high-level-architecture.md
  aws-architecture.md
  cicd-flow.md
  security-flow.md
  request-flow.md
  diagrams/
docs/
  setup.md
  deployment.md
  security.md
  testing.md
  troubleshooting.md
  operations.md
  cost-and-cleanup.md
engineering-decisions/
  ADR-001-aws-platform.md
  ADR-002-eks-deployment.md
  ADR-003-ecr-image-registry.md
  ADR-004-github-actions-oidc.md
  ADR-005-security-scanning.md
  ADR-006-secret-management.md
  ADR-007-local-validation.md
presentation/
  presentation-outline.md
```

The directories and files above describe the desired final documentation set. They are not implementation instructions for this documentation task unless explicitly requested separately.

## 4. README requirements

The README must remain the entry point for the repository and should include:

- application purpose and business requirements
- supported inventory categories and e-checkout behavior
- technology stack and supported Java/Maven versions
- a short architecture summary
- prerequisites for local development
- commands for build, test, and local startup
- links to the documentation sections
- a clear distinction between the current application and planned deployment assets
- known limitations and security considerations
- a documentation index

The README should link to detailed documents rather than duplicating their full content.

## 5. Application and local environment documentation

`docs/setup.md` must document the current application baseline, including:

- Java 11 requirement
- Maven build and packaging
- Spring Boot application startup
- default port 8080
- configuration profiles and their intended use
- H2 support for local/default validation where applicable
- MySQL requirements for development and production profiles
- database configuration without publishing credentials
- commands for `mvn clean compile`, `mvn test`, `mvn package`, and `mvn spring-boot:run`
- sample REST API checks using `curl`
- expected startup and validation outcomes

The setup guide must explain how to handle configuration values through environment variables or a local, ignored configuration file. It must not include real passwords, tokens, webhook URLs, or other secrets.

## 6. Architecture documentation

The architecture documents must describe the target design and label all future components as planned where they are not present in the repository.

### 6.1 High-level architecture

`architecture/high-level-architecture.md` must show the relationship between:

- users or API clients
- internet-facing application entry point
- EKS-hosted Spring Boot service
- application container image
- RDS for MySQL
- AWS networking and IAM
- observability and security tooling
- the CI/CD system

It must include a high-level diagram and a short explanation of trust boundaries, data flow, and deployment boundaries.

### 6.2 AWS architecture

`architecture/aws-architecture.md` must document the planned AWS topology:

- VPC
- public and private subnets across at least two availability zones
- internet gateway and route tables
- NAT gateway considerations
- EKS cluster and worker capacity
- ECR repository
- Application Load Balancer ingress
- RDS MySQL in private subnets
- security groups and least-privilege access
- CloudWatch logging and monitoring
- IAM roles and GitHub Actions OIDC

The document must discuss availability, network isolation, scaling assumptions, and cost trade-offs. It must not imply that AWS resources have been provisioned.

### 6.3 CI/CD flow

`architecture/cicd-flow.md` must describe the progression from pull request or push through:

1. checkout and Java setup
2. Maven compile, test, and package
3. SonarQube quality analysis
4. Snyk, Gitleaks, and other security checks
5. Docker image build and runtime validation
6. Terraform and Kubernetes validation
7. ECR publication for an approved branch
8. EKS deployment and rollout verification
9. post-deployment validation
10. Microsoft Teams notification

Pull requests must validate without deploying production resources. A push to `master` may publish and deploy only after required gates pass.

### 6.4 Security flow

`architecture/security-flow.md` must show security controls at source, dependency, container, infrastructure, runtime, and notification layers. It must identify which findings block the pipeline and how exceptions are documented and approved.

### 6.5 Request flow

`architecture/request-flow.md` must show a client request moving through the load balancer and ingress to the Spring Boot service, then to the database where required. It must cover response flow, logging, and failure points. It should identify the inventory, member, purchase-order, and recommendation API areas without inventing endpoints that are not implemented.

Diagrams may use Mermaid or another maintainable text-based format. Each diagram must have accompanying prose and a clear legend where needed.

## 7. Deployment documentation

`docs/deployment.md` must explain the planned deployment lifecycle:

- build a reproducible JAR
- build and test a container image
- scan the image
- publish an immutable image tag to ECR
- deploy the tag to EKS
- wait for rollout completion
- validate service reachability and application behavior
- roll back to the previous known-good image if validation fails

The document must identify required prerequisites, environment variables, AWS permissions, expected commands, approval points, and cleanup actions. It must distinguish commands that can be run now from commands that depend on future Docker, Terraform, Kubernetes, or workflow files.

## 8. Security documentation

`docs/security.md` must cover:

- SonarQube code quality and quality-gate enforcement
- Snyk dependency vulnerability scanning
- Gitleaks secret detection
- Trivy container and filesystem scanning
- Checkov infrastructure and Kubernetes policy checks
- OWASP ZAP dynamic application testing
- IAM least privilege
- GitHub Actions OIDC instead of long-lived AWS keys
- secret storage and rotation
- database network isolation
- image provenance and immutable tags
- logging and sensitive-data handling
- vulnerability triage and exception ownership

The security document must call out the known risk of credentials in application configuration and provide remediation guidance without reproducing secret values. Security controls must be described as requirements or planned controls until implemented.

## 9. Secret management and notifications

Documentation must define the following future secret or variable references without storing their values:

- `SONAR_TOKEN`
- `SONAR_HOST_URL`
- `SNYK_TOKEN`
- `AWS_ROLE_ARN`
- `AWS_REGION`
- `ECR_REPOSITORY`
- `EKS_CLUSTER_NAME`
- `TEAMS_WEBHOOK_URL`

The documentation must specify where each value is configured, which jobs consume it, who owns it, and how it is rotated. AWS credentials must use short-lived OIDC-issued credentials. Microsoft Teams notifications must report success or failure without exposing credentials, tokens, database values, or sensitive scan output.

## 10. Testing and validation documentation

`docs/testing.md` must document validation in layers:

- Maven compile, test, and package
- local Spring Boot startup
- REST API checks and expected HTTP behavior
- Docker build, startup, logs, API checks, and cleanup
- Terraform formatting, initialization, validation, and plan
- Kubernetes manifest dry runs, rollout checks, service reachability, and self-healing checks
- security-tool execution and blocking thresholds
- post-deployment smoke tests

The guide must state prerequisites and cleanup for each layer. It must not require future implementation files to exist before the current Maven baseline can be tested.

## 11. Troubleshooting documentation

`docs/troubleshooting.md` must provide symptom, likely cause, diagnostic command, and corrective action for at least:

- Maven dependency, compilation, and test failures
- Java version mismatches
- Spring Boot startup failures
- database connectivity and schema problems
- occupied ports
- Docker build and container startup failures
- Terraform initialization, validation, and permission failures
- Kubernetes image pull, scheduling, readiness, service, and rollout failures
- ECR authentication and EKS access failures
- SonarQube, Snyk, Gitleaks, Trivy, Checkov, and ZAP findings
- missing or incorrectly scoped secrets
- Microsoft Teams notification failures

Troubleshooting commands must avoid printing secrets. The guide should include rollback and escalation guidance for deployment failures.

## 12. Operations, cost, and cleanup

`docs/operations.md` must cover:

- health and readiness expectations
- application and infrastructure logs
- metrics and alerting expectations
- backup and restore considerations for MySQL
- deployment and rollback procedures
- incident ownership and escalation
- access review and secret rotation
- routine vulnerability review

`docs/cost-and-cleanup.md` must cover:

- major AWS cost drivers, including EKS, RDS, NAT gateways, load balancing, storage, and data transfer
- cost-conscious choices appropriate for a capstone
- non-production scheduling or shutdown options
- deletion of test containers, images, plans, namespaces, and temporary resources
- verification that no billable AWS resources remain after an experiment

Cleanup guidance must not suggest deleting shared or production resources without an explicit confirmation and ownership check.

## 13. Architecture decision records

Each ADR must contain context, decision, alternatives considered, consequences, security implications, cost implications, and status.

Required ADR topics:

- `ADR-001`: AWS as the target cloud platform
- `ADR-002`: EKS as the Kubernetes deployment platform
- `ADR-003`: ECR as the container image registry
- `ADR-004`: GitHub Actions OIDC for AWS authentication
- `ADR-005`: layered security scanning and blocking gates
- `ADR-006`: secret management without committed credentials
- `ADR-007`: local validation before cloud deployment

ADRs must record decisions made for this project, not generic vendor descriptions. Rejected alternatives should be documented when they materially affected the decision.

## 14. Presentation requirements

`presentation/presentation-outline.md` must provide a concise presentation and demo sequence covering:

- customer problem and application capabilities
- current application architecture
- target AWS architecture
- AI-assisted engineering approach and specification workflow
- DevSecOps pipeline stages
- security controls and blocking gates
- local validation evidence
- planned deployment and rollback flow
- demonstration of representative inventory, member, and purchase-order behavior
- operational considerations, limitations, and lessons learned

The presentation must clearly label implemented behavior versus planned infrastructure and automation.

## 15. Documentation quality rules

All documentation must:

- use consistent terminology for inventory, members, purchase orders, and receipts
- use relative links that match the final repository structure
- include commands in copyable code blocks
- identify prerequisites and expected results
- avoid hard-coded credentials and sensitive values
- identify assumptions and unresolved implementation dependencies
- prefer diagrams that can be reviewed and maintained as text
- keep current-state facts separate from future-state proposals
- avoid duplicating details that belong in another document
- be reviewed for broken links, stale commands, and unsupported claims

## 16. Definition of Done

The documentation set is complete when:

- README links to every required documentation area
- local setup and Maven validation are reproducible
- current application behavior is accurately described
- target AWS, Docker, Terraform, Kubernetes, and CI/CD designs are documented as appropriate
- security tools, thresholds, secrets, and notification behavior are defined
- architecture diagrams cover high-level, AWS, CI/CD, security, and request flows
- troubleshooting, operations, cost, and cleanup guidance is present
- all seven required ADRs exist and follow a consistent format
- the presentation outline supports an end-to-end demonstration
- links and diagrams have been checked
- no documentation contains real secrets
- documentation does not falsely claim that future implementation assets exist

## 17. Scope constraints

This specification does not authorize:

- modification of application source code
- modification of existing tests
- creation of Dockerfiles or Docker Compose files
- creation of Terraform files
- creation of Kubernetes manifests or Helm charts
- creation of GitHub Actions workflow YAML
- creation of runtime secrets or cloud resources
- changes to dependency versions or application configuration

Those activities require separate implementation tasks and validation. The documentation should prepare for them while preserving the current application baseline.
