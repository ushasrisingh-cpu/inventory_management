# Automated platform operations

## Infrastructure workflow

The `Terraform infrastructure` GitHub Actions workflow creates or updates the
selected environment without requiring local Terraform commands.

The workflow deliberately separates planning from modification:

1. Check Terraform formatting and configuration.
2. Run Checkov policy checks.
3. Authenticate to AWS with GitHub OIDC.
4. Create a Terraform plan against remote S3 state.
5. Publish the readable plan to the GitHub Actions summary.
6. Wait for a reviewer to approve or reject the protected environment.
7. Recreate the plan from the same commit and apply it after approval.
8. On the first deployment, push the application image and start one ECS task.
9. Enable CPU and ALB request-count target tracking.

Create GitHub environments named `terraform-dev` and `terraform-prod`. Add a
required reviewer to each environment. For this single-participant capstone,
turn off **Prevent self-review** so the workflow initiator can approve the
deployment. Production should normally require approval from a different
reviewer.

The repository requires these GitHub Actions variables:

- `TERRAFORM_AWS_ROLE_ARN`: ARN of a persistent, least-privilege OIDC role.
- `APPLICATION_DEPLOY_ROLE_ARN`: ARN of the persistent application deployment
  role, which is restricted to the project ECR repository and ECS services.
- `TERRAFORM_STATE_BUCKET`: `inventory-management-650694420501-ap-south-1-archive`.

The OIDC role lives in the persistent archive stack, outside the disposable
dev and prod Terraform states. Its trust policy accepts tokens only from this
repository's `master` branch and the two protected Terraform environments. Its
AWS policy is limited to the Mumbai region, project-prefixed IAM roles, and the
`terraform/` state prefix in the archive bucket. It has no AdministratorAccess
managed policy.

## One-time automation bootstrap

The persistent role must exist before GitHub can automate dev or prod. This is
the only infrastructure apply that must be performed locally:

1. Set `github_repository = "ushasrisingh-cpu/inventory_management"` in the
   archive environment's `terraform.tfvars`.
2. Plan the archive stack and review the addition of the GitHub OIDC provider,
   platform automation role, and inline policy.
3. Apply that reviewed archive plan.
4. Set repository variable `TERRAFORM_AWS_ROLE_ARN` to the
   `platform_automation_role_arn` output.
5. Set repository variable `APPLICATION_DEPLOY_ROLE_ARN` to the
   `application_deploy_role_arn` output.
6. Set repository variable `TERRAFORM_STATE_BUCKET` to the
   `terraform_state_bucket` output.
7. Configure the required reviewers on `terraform-dev` and `terraform-prod`.

After this bootstrap, all dev and prod infrastructure changes use the GitHub
workflow and its approval gate. Do not destroy the archive stack while this
automation is in use.

The remote state uses separate keys:

- `terraform/dev.tfstate`
- `terraform/prod.tfstate`

S3 versioning protects prior state versions, and Terraform's S3 lock file
prevents concurrent modification. The archive stack continues to use its
existing independent state because it owns the state bucket itself.

## Networking decision

Development uses public ECS task IP addresses and no NAT gateway:

```hcl
enable_nat_gateway   = false
ecs_assign_public_ip = true
```

The task security group accepts application traffic only from the ALB security
group. Users access the ALB; the task public IP is used for outbound access to
ECR, CloudWatch Logs, Secrets Manager, S3, and package services. RDS remains
private and accepts MySQL only from the task security group.

Production retains private ECS tasks and per-AZ NAT gateways:

```hcl
enable_nat_gateway   = true
nat_gateway_strategy = "per_az"
ecs_assign_public_ip = false
```

## Autoscaling

Both environments use two target-tracking policies:

- Average ECS CPU utilization: `60%`.
- ALB requests per target: `1000`.

Application Auto Scaling may scale out when either policy requires additional
capacity. Scale-in is conservative because all target-tracking policies must
agree that capacity can be removed. Dev scales between one and two tasks;
production scales between two and four tasks.

## Automated database backups

EventBridge Scheduler starts the existing one-off Fargate backup task every day
at `02:00 UTC` by default. The schedule is configurable with
`database_backup_schedule_expression`.

The scheduler role can only run the database backup task and pass its two ECS
roles. The task creates a consistent MySQL dump, uploads it beneath
`backups/<environment>/`, and exits. S3 lifecycle rules retain these portable
backups for 90 days.

The schedule is removed with its application environment. Previously archived
objects remain in the independent archive bucket.

## Operational safeguards

- Infrastructure apply cannot begin until the GitHub environment is approved.
- Rejecting the deployment makes no AWS changes.
- Workflow concurrency permits only one Terraform operation per environment.
- The application CD workflow checks that ECS and ECR exist and safely skips
  deployment while development infrastructure is offline.
- Saved binary plans are not uploaded as public workflow artifacts because they
  can contain sensitive values.
