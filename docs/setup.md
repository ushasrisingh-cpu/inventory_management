# Local Setup and Validation

## Prerequisites

- Git
- Java 17
- Maven
- Docker
- Terraform 1.5 or later within the repository constraint
- Optional: kubectl, Kustomize support, and Kind

## Application validation

From the repository root:

```bash
mvn clean compile
mvn test
mvn package
```

The expected result is a successful build and a packaged JAR under `target/`. Start the application with the repository's supported local profile:

```bash
mvn spring-boot:run
```

The application listens on port 8080 unless configuration overrides it. Use the readiness endpoint to verify startup:

```bash
curl -fsS http://localhost:8080/actuator/health/readiness
```

## Database configuration

Use the local profile and database approach described in `ai-specifications/application-spec.md`. Keep passwords in environment variables or an ignored local configuration file. Do not commit credentials or print them in troubleshooting output.

## Container validation

```bash
docker build -t inventory-management:local .
docker image inspect inventory-management:local >/dev/null
```

Run the container only after providing the database settings required by the application profile. Remove temporary containers and images after testing.

## Terraform validation

```bash
terraform fmt -check -recursive infrastructure/terraform
terraform -chdir=infrastructure/terraform init -backend=false
terraform -chdir=infrastructure/terraform validate
terraform -chdir=infrastructure/terraform/environments/archive init -backend=false
terraform -chdir=infrastructure/terraform/environments/archive validate
terraform -chdir=infrastructure/terraform/environments/dev init -backend=false
terraform -chdir=infrastructure/terraform/environments/dev validate
terraform -chdir=infrastructure/terraform/environments/prod init -backend=false
terraform -chdir=infrastructure/terraform/environments/prod validate
```

## Kubernetes portability validation

```bash
kubectl kustomize infrastructure/kubernetes/overlays/dev >/tmp/inventory-dev.yaml
kubectl kustomize infrastructure/kubernetes/overlays/prod >/tmp/inventory-prod.yaml
```

These manifests support local portability and policy scanning. AWS deployment uses ECS Fargate.
