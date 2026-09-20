# S3 Log Archive and Database Backups

## Design

The archive stack is independent from dev and production. Its private bucket blocks public access, denies insecure transport, enables AES256 server-side encryption and versioning, expires `logs/` objects after 30 days, expires `backups/` objects after 90 days, and aborts incomplete multipart uploads after seven days. `force_destroy = false` prevents routine Terraform destruction of retained data.

RDS automated backups remain the primary managed recovery mechanism. The SQL file in S3 is a portable secondary backup.

## Deployment order

1. Apply `infrastructure/terraform/environments/archive`.
2. Apply the dev or production application environment.
3. Deploy the application image.
4. Run and verify required backup and log-archive operations.
5. Destroy the disposable application environment when testing ends.
6. Leave the archive stack running until its retention obligation ends.

## Requirements

The scripts default to:

- AWS profile `devsecops-terraform`
- Region `ap-south-1`
- Application environment `dev`
- Archive state in `infrastructure/terraform/environments/archive`

Override defaults only through the documented environment variables. Reauthenticate the underlying temporary AWS profile when its session expires.

## Archive application logs

```bash
scripts/export-cloudwatch-logs.sh \
  /aws/ecs/inventory-management/dev \
  logs/application/dev \
  1
```

The script reads CloudWatch events directly, writes compressed JSON, and uploads it to the archive bucket. Direct reading replaced the CloudWatch export-task API after that API incorrectly reported a deleted KMS association.

## Archive VPC flow logs

```bash
scripts/export-cloudwatch-logs.sh \
  /aws/vpc/inventory-management/dev/flow-logs \
  logs/vpc-flow/dev \
  1
```

## Automated portable database backup

EventBridge Scheduler runs the registered one-off Fargate backup task every day
at `02:00 UTC` by default. Change
`database_backup_schedule_expression` when a different schedule is required.
The schedule uses the same public task networking as development and the same
private task networking as production.

To start an additional backup on demand, run:

```bash
scripts/run-database-backup.sh
```

The script starts the registered one-off Fargate backup task and waits for it to stop. Success requires exit code `0` for both `database-dump` and `backup-upload`.

The dump command uses options compatible with the managed RDS user:

```text
--single-transaction --quick --skip-lock-tables --set-gtid-purged=OFF --no-tablespaces
```

## Verify retained objects

```bash
bucket="$(
  AWS_PROFILE=devsecops-terraform \
  terraform -chdir=infrastructure/terraform/environments/archive \
  output -raw archive_bucket_name
)"

AWS_PROFILE=devsecops-terraform aws s3api list-objects-v2 \
  --bucket "$bucket" \
  --query 'Contents[].{Key:Key,SizeBytes:Size,Modified:LastModified}' \
  --output table \
  --no-cli-pager
```

Use `head-object` for the selected key and verify nonzero size, `AES256`, and a version ID.

## Restore verification

Restore portable SQL only into an isolated approved database. Download the selected object version, start a clean compatible MySQL instance, import the SQL file, and validate schema and representative record counts. The capstone restore test recovered eight tables, four member records, and eight product records. Remove the temporary database after verification.

Never restore over the active application database as an informal test.

## Cleanup warning

Destroying dev must not include the archive bucket. Destroy the archive environment only after an explicit retention and ownership review. Copy or deliberately remove retained object versions before attempting archive destruction.
