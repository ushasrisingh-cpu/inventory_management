# Deployment Guide

## Deployment model

Terraform creates the AWS foundation. CI validates the source and artifacts. CD publishes an immutable image and updates ECS. The archive environment has an independent lifecycle.

## Prerequisites

- Authenticated AWS CLI profile with approved permissions
- Terraform initialized for the selected environment
- GitHub OIDC role created by Terraform
- GitHub repository variables configured
- `DEV_INFRA_ENABLED=false` until dev infrastructure is ready

Never place AWS access keys or database passwords in workflow files.

## Archive first

Create the persistent archive before an application environment:

```bash
AWS_PROFILE=devsecops-terraform \
terraform -chdir=infrastructure/terraform/environments/archive plan -out=archive.tfplan

AWS_PROFILE=devsecops-terraform \
terraform -chdir=infrastructure/terraform/environments/archive apply archive.tfplan
```

Inspect every plan before applying it.

## Dev bootstrap

An empty ECR repository cannot start the application task. Bootstrap dev with zero desired tasks and autoscaling disabled. Apply the reviewed Terraform plan, allow CI/CD to push the first image and deploy one task, then enable autoscaling and apply its reviewed plan.

## CD deployment

After successful CI on `master`, set `DEV_INFRA_ENABLED=true` only while the target infrastructure exists. CD:

1. Assumes the deployment role through OIDC.
2. Builds the image.
3. Pushes the commit-SHA tag to ECR.
4. Downloads the current task definition.
5. Replaces the application image.
6. Registers and deploys a new revision.
7. Waits for service stability.

Verify desired, running, pending, and rollout state, then check the readiness endpoint through the ALB.

## Rollback

Identify the previous successful ECS task-definition revision and immutable image. Redeploy that revision or image through the approved workflow. Inspect ECS events, stopped-task reasons, CloudWatch logs, and ALB target health before retrying.

## Teardown

Set `DEV_INFRA_ENABLED=false` before destroying dev. Create a saved destroy plan, verify that no archive bucket appears, and apply only the dev plan. Never run the dev command against `environments/archive`.
