# CI CD Flow

## Pipeline overview

```mermaid
flowchart LR
    Commit[Pull request or master push] --> Tests[Maven tests]
    Tests --> Package[Maven package and JAR artifact]
    Package --> Sonar[SonarCloud Quality Gate]
    Commit --> Secrets[Gitleaks]
    Commit --> TF[Terraform format and validate]
    TF --> Checkov[Checkov Terraform]
    Commit --> K8s[Render Kustomize overlays]
    K8s --> KCheck[Checkov Kubernetes]
    Package --> Image[Docker build]
    Image --> Trivy[Trivy image gate]
    Tests --> CI{CI successful}
    Secrets --> CI
    Checkov --> CI
    KCheck --> CI
    Trivy --> CI
    Commit --> InfraValidate[Terraform format validate Checkov]
    InfraValidate --> InfraPlan[Remote state Terraform plan]
    InfraPlan --> Approval[Protected environment approval]
    Approval --> InfraApply[Terraform apply]
    InfraApply -->|First deployment only| Bootstrap[Push first image deploy task enable autoscaling]
    CI -->|master and ECS ECR exist| OIDC[Assume AWS role with OIDC]
    OIDC --> ECR[Push commit-SHA image]
    ECR --> Render[Render ECS task definition]
    Render --> Deploy[Deploy and wait for stability]
```

## CI behavior

Pull requests and pushes to `master` run CI. Maven tests must pass before packaging. The JAR is uploaded as a workflow artifact. Gitleaks scans full Git history. Terraform is formatted, initialized without a backend, and validated for the reusable root and environments. Checkov scans Terraform and rendered Kubernetes overlays. Docker image creation must succeed, and Trivy blocks fixable high or critical image vulnerabilities.

SonarCloud analysis is enabled for reviewed changes. The Quality Gate is part of the current delivery evidence and passed with no new security issues or hotspots in the latest reviewed change.

## CD behavior

The Terraform infrastructure workflow runs automatically for dev on a `master` push and can be dispatched manually for dev or prod. It validates, creates a remote-state plan, publishes the plan summary, and waits for protected-environment approval before apply. CD starts only after successful CI on `master`, or through manual dispatch on `master`. It checks for the ECS service and ECR repository, then skips safely if dev is deliberately destroyed.

The workflow requests short-lived AWS credentials using OIDC, logs in to ECR, tags the image with the source commit SHA, pushes it, downloads the current ECS task definition, replaces the container image, deploys the new revision, and waits for service stability.

## Rollback and failure handling

ECS deployment circuit-breaker settings and service-stability waiting detect failed rollouts. Operators inspect ECS events, task logs, target health, and the task-definition revision. Recovery uses the last known-good immutable image and task revision. CI failures prevent CD from starting.

## Future improvements

- Add dynamic application security testing with OWASP ZAP.
- Add Snyk only if it provides value beyond existing dependency and image controls.
- Add deployment notifications without exposing scan output or secrets.
