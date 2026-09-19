# Operations Guide

## Routine checks

- Confirm ECS desired, running, and pending counts.
- Confirm the primary deployment rollout is completed.
- Check ALB target health and application readiness.
- Review CloudWatch application logs and VPC flow logs.
- Review autoscaling activities and CloudWatch alarm states.
- Review CI security results and dependency findings.
- Confirm backup and archive retention requirements.

## Deployment ownership

CI validates each approved source revision. CD owns deployed task-definition revisions. Application Auto Scaling owns desired count while enabled. Terraform owns foundational infrastructure and deliberately ignores fields owned by CD and autoscaling.

## Backup operations

RDS automated backups are the primary managed recovery mechanism. The one-off Fargate task produces a portable secondary SQL backup under `backups/<environment>/`. Run it after the target environment exists and verify both container exit codes and the S3 object metadata.

## Log archives

The log archive script reads CloudWatch events directly, writes compressed JSON, and uploads it beneath `logs/`. Application and VPC flow logs use separate prefixes. Direct reading replaced the CloudWatch export-task API after its KMS preflight produced an incorrect deletion-state error.

## Incident response

For deployment incidents, stop further releases, inspect CI/CD and ECS evidence, identify the last known-good revision, and roll back. For suspected credential exposure, revoke or rotate the affected value, review logs, run Gitleaks, and document the incident without copying the secret.

## Access review

Review GitHub repository access, OIDC trust conditions, deployment-role permissions, ECS roles, secret policies, and archive-bucket policies. Remove unused identities and avoid wildcard permissions unless an AWS API requires them with compensating scope.

## Environment status

Keep `DEV_INFRA_ENABLED=false` while dev is destroyed. The archive stack may remain active independently. Before recreating dev, review current costs, Terraform plans, CI status, and retained archive requirements.
