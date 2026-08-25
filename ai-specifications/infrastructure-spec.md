# Inventory Management System Infrastructure Specification

## 1. Target cloud: AWS

- Primary target cloud: AWS
- Production-inspired architecture for a single Spring Boot application running in Kubernetes.
- This spec assumes a containerized deployment model for the application, with EKS as the primary target and ECS treated only as an optional alternative if there is a future operational constraint.
- AWS is the chosen target because it provides a mature ecosystem for VPC networking, managed Kubernetes, container registries, managed databases, ingress/ALB routing, monitoring, secrets management, and IAM-based access controls.

## 2. Application runtime summary (source of truth)

This infrastructure design is based on the application analysis captured in `application-spec.md`.

Key application facts:

- Java 11 Spring Boot application
- Maven build produces a JAR package
- MySQL is the target database in dev/prod
- REST API is exposed under `/api/v1`
- Application runs on default Spring Boot port 8080
- No built-in actuator health endpoint exists
- No Spring Security layer is configured
- Secret values are currently embedded in source config files and must be moved out of source control
- Intended deployment model is a single application service, not a distributed microservice system

## 3. Network architecture

### 3.1 VPC

- One dedicated VPC for the application environment.
- VPC CIDR should be chosen to allow room for future growth while staying private and easy to reason about.
- Recommended starting CIDR:
  - `10.20.0.0/16`
- This leaves enough room for multiple subnets and future service expansion without overlapping with other corporate or test networks.

### 3.2 Availability zones

- Use at least 2 Availability Zones for production-inspired deployment.
- Recommended AZ layout:
  - `us-east-1a`
  - `us-east-1b`
- For a simple capstone deployment, two AZs are the minimum meaningful production pattern.

### 3.3 Public subnets

- Public subnets are used for internet-facing traffic and shared edge services.
- Recommended public subnet CIDRs:
  - `10.20.1.0/24` in AZ-a
  - `10.20.2.0/24` in AZ-b
- Public subnet purposes:
  - ALB ingress
  - NAT Gateway egress when needed
  - optional bastion or admin network access only if required

### 3.4 Private subnets

- Private subnets host the application workloads and the managed database.
- Recommended private subnet CIDRs:
  - `10.20.11.0/24` in AZ-a
  - `10.20.12.0/24` in AZ-b
- Additional database-only private subnets may be used for better separation:
  - `10.20.21.0/24` in AZ-a
  - `10.20.22.0/24` in AZ-b
- Private subnets should contain:
  - EKS worker nodes
  - RDS MySQL instances
  - any supporting private services

### 3.5 Route tables

- Public route table:
  - subnet association: public subnets
  - route to Internet Gateway for `0.0.0.0/0`
- Private route table:
  - subnet association: private app and database subnets
  - route to NAT Gateway for outbound internet access
  - no direct inbound internet route

### 3.6 Internet Gateway

- One Internet Gateway is required for the VPC.
- It enables the ALB and any public-facing resources to receive inbound traffic from users.
- The ALB is internet-facing and should be attached to the public subnets.

### 3.7 NAT Gateway

- NAT Gateway is required for private subnets to reach outbound internet resources without exposing private resources publicly.
- Required use cases:
  - EKS worker nodes pulling images from ECR
  - private resources reaching AWS APIs
  - patching or package updates when needed
  - outbound access for private services
- NAT Gateway cost is significant; for a capstone, a cheaper alternative may be a single NAT Gateway in one AZ or a NAT instance in a local validation environment, but production use should prefer highly available NAT Gateway pairs across AZs.

### 3.8 CIDR strategy

Recommended strategy:

- VPC: `10.20.0.0/16`
- Public subnets: `10.20.1.0/24`, `10.20.2.0/24`
- Private app subnets: `10.20.11.0/24`, `10.20.12.0/24`
- Private DB subnets: `10.20.21.0/24`, `10.20.22.0/24`
- Reserved room for future services, EKS pods, and additional AWS-managed components

This allows future growth while avoiding overlap with typical corporate or lab networks.

## 4. Container infrastructure

### 4.1 ECR repository for Docker images

- Amazon ECR is the required Docker image registry.
- Docker images for the Java application must be pushed to ECR.
- Repository naming recommendation:
  - `inventory-management/app`
  - or a multi-environment pattern such as `inventory-management/dev` and `inventory-management/prod`
- Recommended lifecycle policy:
  - keep a small number of recent images
  - set retention based on dev/prod needs
  - avoid keeping stale images indefinitely

### 4.2 EKS as the primary Kubernetes target

- Amazon EKS is the primary target for production-inspired Kubernetes deployment.
- Use EKS managed node groups or self-managed node groups depending on team preference.
- Recommended topology:
  - 1 cluster for dev and prod or a separate cluster per environment
  - at least 2 AZs
  - managed node groups in private subnets

### 4.3 ECS as optional alternative

- ECS should be documented only as an optional alternative and not the primary target.
- EKS remains the preferred target because the architecture requirement explicitly calls for Kubernetes and future GitOps or cluster-based operations.

## 5. Load balancing

### 5.1 Application Load Balancer

- Use an internet-facing Application Load Balancer (ALB) in front of the Kubernetes application.
- ALB is the preferred ingress layer for HTTP/HTTPS traffic.
- It routes incoming requests to the Kubernetes service or ingress-managed targets.

### 5.2 Inbound traffic flow

Traffic flow should be:

1. Client hits ALB DNS name
2. ALB receives traffic on port 80 or 443
3. ALB forwards to Kubernetes Ingress or NodePort/LoadBalancer target group
4. Kubernetes service routes traffic to application pods on port 8080
5. Application processes requests and talks to RDS MySQL

### 5.3 Target routing to Kubernetes service/application

- Preferred pattern: ALB + Kubernetes Ingress Controller (e.g., AWS Load Balancer Controller)
- Ingress routes `/` or `/api` traffic to the Spring Boot service
- Service uses a target port of 8080
- This provides a cleaner production pattern than exposing raw node IPs directly

## 6. Security groups

### 6.1 ALB security group

- Inbound:
  - allow HTTP from `0.0.0.0/0` on port 80
  - allow HTTPS from `0.0.0.0/0` on port 443
- Outbound:
  - allow traffic to EKS worker nodes or Kubernetes ingress targets on the required application port (normally 80/443 or the NodePort/ALB target port)
- Restrict as necessary to only required ports and CIDRs

### 6.2 EKS/node security groups

- Worker node security group inbound:
  - allow traffic from ALB security group to application port 8080 or the designated NodePort target port
  - allow inter-node communication for Kubernetes networking
  - allow SSH only if absolutely required and only from a locked-down admin CIDR
- Worker node security group outbound:
  - allow outbound to the internet via NAT for package retrieval or ECR access
  - allow outbound to RDS databases on MySQL port 3306
  - allow DNS egress to VPC endpoints or AWS DNS services

### 6.3 Application port access

- Application listens on port 8080 by default
- Security groups should allow traffic from the ALB to port 8080 or from the ingress controller service to the pod port as defined by the K8s networking model.
- Database access is restricted to application security groups only, not publicly exposed.

### 6.4 Least privilege

- Use explicit allow rules only.
- Avoid broad `0.0.0.0/0` egress unless strictly necessary.
- Maintain separate SGs for:
  - ALB
  - EKS worker nodes
  - RDS database
  - optional bastion/admin tunnel

## 7. IAM requirements

### 7.1 GitHub Actions deployment role

- Use an IAM role for GitHub Actions via OIDC federation instead of long-lived AWS access keys.
- Recommended pattern:
  - GitHub OIDC provider in AWS IAM
  - role with trust policy limited to the target GitHub repo and branch or environment
- Permissions should be limited to:
  - ECR push/pull access
  - EKS update-kubeconfig or cluster access for deployment automation
  - Terraform state access when implemented later
  - optional S3 access for artifacts or remote state only if required

### 7.2 EKS access role

- Use a dedicated IAM role for administrators and CI/CD automation.
- Recommended to minimize direct root access.
- Access should be granted via IAM roles rather than embedded static keys.

### 7.3 ECR push/pull permissions

- ECR repository policy should allow:
  - GitHub Actions role to push images
  - EKS nodes or workload identity to pull images as needed
- Principle of least privilege should be enforced.

### 7.4 S3 access

- S3 should only be used if there is a concrete need for artifacts, logs, backups, or Terraform state.
- This application does not inherently require S3 for runtime.
- Do not treat S3 as the image registry; ECR is the correct registry.

### 7.5 OIDC recommendation

- Prefer OIDC federation for GitHub Actions over long-lived static AWS access keys.
- This is the recommended secure pattern for a capstone or production-inspired CI/CD design.

## 8. Kubernetes deployment requirements

### 8.1 Namespace

- Namespace example: `inventory-management`
- Optional environment-specific namespaces:
  - `inventory-management-dev`
  - `inventory-management-prod`

### 8.2 Deployment

- A single Kubernetes `Deployment` is sufficient for the current application architecture.
- Recommended deployment name: `inventory-management-app`
- The app should expose container port 8080.
- Replicas should be at least 2 in production-inspired environments.

### 8.3 Service

- Use a Kubernetes `Service` to expose the application internally.
- Type: `ClusterIP` for internal routing; ALB/Ingress then routes externally.
- Service port should map to the app port (8080) and expose a stable internal service name.

### 8.4 Ingress or ALB integration

- Preferred pattern: AWS Load Balancer Controller with Kubernetes Ingress.
- Ingress should route HTTP traffic to the application service.
- This keeps the app off directly exposed node IPs and aligns with AWS best practices.

### 8.5 Replicas

Recommended initial replicas:

- `dev`: 1 to 2 replicas
- `prod`: 2 or more replicas
- Production-inspired minimum: 2 replicas spread across AZs

### 8.6 Readiness and liveness probes

- Readiness probe:
  - HTTP GET to `/` or a lightweight health endpoint, if implemented later
  - default threshold should be simple and low-latency
- Liveness probe:
  - similar mechanism but with a slightly more forgiving threshold
- At minimum, the application should expose a health or readiness endpoint eventually because Kubernetes self-healing requires health-based decisions.
- Today the app does not have built-in actuator health checks; this should be added in a future implementation task.

### 8.7 Resource requests and limits

Example baseline for a small app:

- requests:
  - CPU: 250m
  - memory: 512Mi
- limits:
  - CPU: 500m or 750m
  - memory: 1Gi

These values may be tuned after load testing; the app is small but still has a database dependency and a web API.

### 8.8 Self-healing behavior

Kubernetes self-healing should include:

- restart failed pods
- reschedule pods on unhealthy nodes
- maintain minimum replica counts
- allow rolling updates without downtime

### 8.9 Rolling deployment strategy

- Use a rolling update strategy with a maximum surge and maximum unavailable setting.
- Example:
  - maxUnavailable: 0
  - maxSurge: 1
- This reduces risk during updates and helps maintain application availability.

### 8.10 ConfigMap and Secret handling

- Use `ConfigMap` for non-sensitive config such as:
  - Spring profile name
  - app port
  - log level
  - service URLs that are not secrets
- Use Kubernetes Secret or AWS Secrets Manager-backed secret injection for:
  - database username/password
  - TLS material
  - any other sensitive config
- Do not store database credentials in source control.

### 8.11 Autoscaling considerations

- Kubernetes Horizontal Pod Autoscaler (HPA) should be considered once the app is running in EKS.
- Baseline autoscaling metrics:
  - CPU utilization
  - memory utilization
  - optional custom metrics later
- This is especially useful if demand increases or the app starts handling more checkout traffic.

## 9. Database architecture

### 9.1 Current MySQL requirement

- The application is explicitly designed around MySQL in dev/prod profiles.
- The configuration files reference MySQL databases named:
  - `kasperin_dev`
  - `kasperin_prod`
- The SQL script under `src/main/scripts/configure-mysql.sql` creates the required MySQL databases and service accounts.

### 9.2 Recommended production database

- Use Amazon RDS for MySQL in production.
- Place the database in private subnets.
- Use a Multi-AZ deployment for better availability.
- Keep database access restricted to the application security group only.

### 9.3 Security and secret handling

- Database credentials must not be stored in source control.
- Use AWS Secrets Manager or Kubernetes secrets managed via external secret tools.
- The application should consume DB credentials via environment variables or secret injection.

### 9.4 RDS placement and connectivity

- RDS should live in private database subnets.
- Traffic path:
  - app pods -> service -> RDS MySQL over port 3306
- Public access should be disabled.
- Database should not be directly internet-accessible.

## 10. Storage

### 10.1 S3 requirement assessment

This application does not appear to require S3 for its core runtime logic.

The application stores and serves inventory data in a MySQL database and does not show evidence of direct S3 usage for:

- object storage
- static assets
- media uploads
- file-based content hosting

### 10.2 Proper use of S3

S3 may be justified for:

- logs or exports
- backups
- artifact retention
- operational support data

But S3 is not required as a Docker image registry.

### 10.3 Docker image storage

- Docker images must be stored in Amazon ECR.
- ECR is the authoritative registry for container images.

## 11. Observability

### 11.1 CloudWatch logs

- Send application logs to CloudWatch Logs.
- Log groups should be organized by environment and app component.
- This is important because the app currently logs inventory and operational events but lacks formal centralized logging configuration.

### 11.2 Kubernetes/EKS monitoring

- Use EKS-native monitoring and CloudWatch integration.
- Track:
  - pod status
  - restart count
  - CPU/memory utilization
  - networking
  - node health

### 11.3 Health checks

- Use ALB target health checks for service-level health verification.
- In Kubernetes, readiness/liveness probes should be defined on the application deployment.
- The current app does not include a built-in actuator health endpoint, so that should be added in future implementation tasks.

### 11.4 Future Prometheus/Grafana option

- Prometheus and Grafana can be added later for application metrics and dashboards.
- This is optional and not required for the initial capstone deployment, but it is a strong future enhancement.

## 12. Availability and resilience

### 12.1 Multi-AZ design

- The architecture should run across at least 2 AZs.
- This supports resilience in the event of an AZ failure.

### 12.2 Minimum replica recommendations

- Minimum production-inspired replica count: 2
- For capstone validation: 1 or 2 depending on local resource constraints
- Keep a deployment model that supports scaling with HPA later.

### 12.3 EKS self-healing

- EKS should use managed node groups and minimum replica counts.
- Failed pods should restart automatically.
- Node replacements should be handled by the cluster lifecycle.

### 12.4 RDS backup considerations

- Use RDS automated backups.
- Configure retention periods appropriate to the environment.
- For production-inspired deployment, Multi-AZ and backup retention are recommended.

### 12.5 Failure handling

The design should account for:

- single AZ failure
- unhealthy app pods
- database connectivity issues
- ALB or ingress issues
- ECR image pull failures
- secrets rotation

## 13. Cost considerations

### 13.1 Major cost drivers

- NAT Gateway: recurring monthly cost
- EKS cluster and workers: operational cost for the control plane and node compute
- ALB: internet-facing load balancing cost
- RDS MySQL: managed database cost, especially Multi-AZ

### 13.2 Cost control for capstone

For a capstone environment, cheaper or simpler alternatives include:

- single-AZ design for validation and dev
- single NAT Gateway instead of dual NAT Gateways
- smaller instance types for EKS nodes
- lower RDS instance class or non-production configuration
- local validation with Docker + kind/minikube instead of full AWS deployment

### 13.3 Production-inspired but cost-aware design

- Keep the design production-inspired, but use the smallest practical AWS resources for validation or capstone use.
- Avoid overprovisioning at the first pass.

## 14. Local validation strategy

Because dedicated AWS resources may not be available, the design should be validated locally using the following tools and workflows.

### 14.1 Docker

- Build the application image locally with Docker.
- Validate the container startup path and port exposure.
- Confirm the app binds to port 8080 as expected.

### 14.2 Kind or Minikube

- Use Kind for a local Kubernetes cluster or Minikube if preferred.
- Validate the Kubernetes deployment, service, and ingress assumptions.
- Confirm resource requests, readiness probes, and rolling updates work correctly.

### 14.3 Terraform validate

- Run `terraform validate` to check syntax and provider configuration.
- This is required once implementation files are created.

### 14.4 Terraform fmt

- Run `terraform fmt -check` or `terraform fmt` to ensure code formatting compliance.
- This is part of the implementation quality gate.

### 14.5 Terraform plan

- Use `terraform plan` where possible to validate infrastructure intent before deployment.
- This is especially useful for VPC, EKS, ALB, and RDS design validation.

### 14.6 Checkov

- Run Checkov to scan Terraform and Kubernetes configuration for security and compliance issues.
- Checkov should be part of the validation stage before any real AWS deployment.

### 14.7 Trivy

- Use Trivy to scan container images for vulnerabilities.
- Also useful for scanning local Docker images before pushing to ECR.

### 14.8 Local Kubernetes deployment

- Use local cluster tooling to validate Helm or Kubernetes manifests in a non-production environment.
- Validate networking, service exposure, and config injection before AWS deployment.

## 15. Infrastructure repository structure

A future implementation should organize the repo like this:

- `infrastructure/`
  - `terraform/`
    - `modules/`
    - `environments/`
      - `dev/`
      - `prod/`
- `kubernetes/`
  - `base/`
  - `overlays/`
    - `dev/`
    - `prod/`
- `docs/` (optional)
- `scripts/` (optional automation helpers)

This structure separates infrastructure code from Kubernetes manifests and keeps environments easy to manage.

## 16. Assumptions, risks, trade-offs, and constraints

### Assumptions

- The project is a single application service with a MySQL dependency.
- It is not a high-scale distributed application.
- It is designed for an AWS production-inspired architecture, not a full multi-service platform.
- A straightforward EKS + ALB + RDS topology is appropriate and sufficient.

### Risks

- The current application has no built-in security controls and no actuator health endpoint.
- Raw credentials are currently kept in source config files.
- The app may need enhancements before production deployment, especially health checks and secure configuration.
- Current dependency versions are somewhat dated, which increases risk in a future production upgrade path.

### Trade-offs

- EKS is chosen as the primary target because Kubernetes is explicitly required.
- ALB is chosen because it handles ingress and TCP/HTTP routing cleanly in AWS.
- RDS MySQL is chosen because the application already expects MySQL and it is a safe managed choice.
- NAT Gateway adds cost but ensures secure private networking.
- Using a simpler local kind/minikube validation path reduces AWS dependency while still validating design assumptions.

### Constraints

- No Terraform files are to be created in this phase.
- No Kubernetes YAML files are to be created in this phase.
- No Dockerfile is to be created in this phase.
- No GitHub Actions workflows are to be created in this phase.
- No application source code modifications are allowed.

## 17. Acceptance criteria for future Terraform/Kubernetes implementation

The future implementation should be considered complete only when all of the following are true:

1. Terraform defines a VPC with public and private subnets across at least two AZs.
2. Terraform creates an Internet Gateway and NAT Gateway(s) appropriately.
3. Terraform provisions an EKS cluster with private worker nodes.
4. Terraform provisions an ALB or ingress-enabled path to the app.
5. Terraform provisions Amazon RDS for MySQL in private subnets.
6. Application secrets are not stored in source control and are managed via Secrets Manager or equivalent secret injection.
7. Kubernetes manifests define a namespace, Deployment, Service, and Ingress or ALB integration.
8. Deployment includes resource requests/limits, readiness probe, liveness probe, and rolling update strategy.
9. The app is deployed with at least 2 replicas in a production-like environment.
10. Observability includes CloudWatch logs and application health monitoring.
11. Security groups enforce least privilege for ALB, EKS nodes, and RDS.
12. IAM is implemented with least privilege and GitHub Actions uses OIDC instead of static keys.
13. The design validates locally with Docker, Kind/Minikube, Terraform validate/fmt/plan, Checkov, and Trivy.
14. The infrastructure design remains aligned with the application specification and operational constraints.

## 18. Architecture decision summary

Chosen architecture:

- AWS VPC with public and private subnets across 2 AZs
- EKS as the primary container platform
- ECR as the image registry
- ALB as the internet-facing entry point
- RDS MySQL in private subnets
- IAM with OIDC-based GitHub Actions
- CloudWatch-based monitoring and log aggregation
- local validation using Docker, Kind/Minikube, Terraform, Checkov, and Trivy

This architecture is appropriate for a single-application, production-inspired deployment while remaining cost-conscious and suitable for a capstone environment.

## 19. Implementation status

This document defines the target infrastructure design only.

The following are intentionally not yet created:

- Terraform files
- Kubernetes manifests
- Dockerfiles
- GitHub Actions workflows
- application source code changes

The next implementation stage, if requested, would be to build the Terraform modules and Kubernetes manifests to satisfy this specification.
