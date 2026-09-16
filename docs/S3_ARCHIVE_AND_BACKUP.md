# S3 log archive and database backups

## Design

The archive bucket is private, blocks all public access, requires HTTPS,
uses S3-managed encryption, enables versioning, and has lifecycle retention:

- `logs/`: deleted after 30 days
- `backups/`: deleted after 90 days
- incomplete multipart uploads: aborted after 7 days

CloudWatch application and VPC flow logs can be exported to `logs/`.

Database backups use a one-off ECS Fargate task inside the VPC:

1. `mysql:8.4` runs `mysqldump` against private RDS.
2. The dump is stored temporarily in the task.
3. An AWS CLI container uploads it to `backups/<environment>/`.
4. The task stops.

The application task has no S3 write permission. A separate least-privilege
backup role can write only beneath `backups/`.

## Requirements

The persistent archive stack must be deployed before the application environment. The scripts use:

- AWS profile `devsecops-terraform`
- Region `ap-south-1`
- Application environment `dev` by default
- Archive state in `infrastructure/terraform/environments/archive`

Override these with `AWS_PROFILE`, `AWS_REGION`, `TF_ENVIRONMENT`, or `ARCHIVE_TF_DIRECTORY`.

## Deployment order

1. Apply `environments/archive` first.
2. Apply the dev or prod application environment.
3. Destroy dev or prod when finished; leave the archive stack running.

## Export application logs

CloudWatch logs can take up to 12 hours to become exportable.

```bash
scripts/export-cloudwatch-logs.sh \
  /aws/ecs/inventory-management/dev \
  logs/application/dev \
  1

```

## Export VPC flow logs

Only one CloudWatch Logs export task can run at a time. Wait for the first
export to finish before starting this command:

```bash
scripts/export-cloudwatch-logs.sh \
  /aws/vpc/inventory-management/dev/flow-logs \
  logs/vpc-flow/dev \
  1
```

## Create a database backup

```bash
scripts/run-database-backup.sh
```

A successful task should report exit code `0` for both `database-dump` and
`backup-upload`.

## Verify archive objects

```bash
bucket="$(
  AWS_PROFILE=devsecops-terraform \
  terraform -chdir=infrastructure/terraform/environments/archive \
  output -raw archive_bucket_name
)"

AWS_PROFILE=devsecops-terraform aws s3 ls \
  "s3://$bucket/logs/" \
  --recursive

AWS_PROFILE=devsecops-terraform aws s3 ls \
  "s3://$bucket/backups/" \
  --recursive
```

## Important

RDS automated backups remain the primary recovery mechanism. The SQL dump in
S3 is a portable secondary backup. Test restoration before treating any backup
as production-ready.

The archive stack is independent from dev and prod. Destroying the application
environment does not destroy archived logs or backups.

The bucket has `force_destroy = false`. Destroy the archive stack only when its
retained objects have been deliberately copied or removed.
