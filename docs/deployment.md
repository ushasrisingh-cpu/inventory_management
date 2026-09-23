# Deployment Guide

## Deployment model

The Terraform infrastructure workflow creates the approved AWS foundation. CI validates source and artifacts. CD publishes an immutable image and updates an existing ECS service. The archive environment has an independent lifecycle.

## Prerequisites

- Persistent archive stack and GitHub OIDC roles created during the one-time bootstrap
- GitHub repository variables configured
- Protected GitHub environments `terraform-dev` and `terraform-prod` with required reviewers

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

## Automated dev and prod workflow

On every push to `master`, the workflow validates, scans, and creates a dev plan. A manual run offers a dev or prod environment choice. It posts the readable plan to the GitHub Actions summary and waits for `terraform-dev` or `terraform-prod` approval. Rejecting the approval makes no AWS changes.

For a first deployment, Terraform creates the platform with zero tasks, publishes the first immutable image after the approved apply, deploys one ECS task, and enables autoscaling. Later changes reuse the existing platform; CD deploys only after successful CI.

## CD deployment

After successful CI on `master`, CD:

1. Checks that the dev ECS service and ECR repository exist; otherwise it skips safely.
2. Assumes the deployment role through OIDC.
3. Builds the image.
4. Pushes the commit-SHA tag to ECR.
5. Downloads the current task definition.
6. Replaces the application image.
7. Registers and deploys a new revision.
8. Waits for service stability.

Verify desired, running, pending, and rollout state, then check the readiness endpoint through the ALB.

## Rollback

Identify the previous successful ECS task-definition revision and immutable image. Redeploy that revision or image through the approved workflow. Inspect ECS events, stopped-task reasons, CloudWatch logs, and ALB target health before retrying.

## Teardown

Create a saved destroy plan, verify that no archive bucket appears, and apply only the dev plan. CD will safely skip while infrastructure is absent. Never run the dev command against `environments/archive`.
