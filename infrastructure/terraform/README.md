# Terraform infrastructure

This stack deploys an ECS Fargate application in `ap-south-1` (Mumbai): VPC public and private subnets, encrypted ECR, platform KMS, optional Flow Logs, private encrypted MySQL RDS, a public HTTP ALB, and optional scoped GitHub Actions OIDC. ECS uses Fargate `awsvpc`, container port `8080`, IP targets, a configurable `/actuator/health/readiness` check, encrypted CloudWatch logs, deployment rollback, and ECS Exec disabled. RDS creates the encrypted master secret through AWS Secrets Manager; Terraform accepts no database password.

Dev uses `ecs_desired_count = 0`, `enable_nat_gateway = false`, and public task IPs so an image can be pushed before starting tasks. Prod uses private tasks (`ecs_assign_public_ip = false`), per-AZ NAT, Multi-AZ RDS, deletion protection, final snapshots, Performance Insights, Enhanced Monitoring, and longer log retention.

Root and environment outputs provide the ECR repository URL, ECS cluster and service names, ALB DNS name, RDS endpoint, sensitive managed secret ARN, GitHub role ARN, and platform KMS ARN. The ECS execution role is scoped to the ECR repository, ECS log group, managed RDS secret, and platform key.

Use the Mumbai examples in `terraform.tfvars.example` and `environments/*/terraform.tfvars.example`. Do not run `terraform apply`, deploy, initialize, validate, or Checkov as part of this migration.
## ECS service autoscaling

The ECS service supports CPU target-tracking autoscaling. Development uses a
minimum of one task and a maximum of two tasks; production uses a minimum of
two tasks and a maximum of four tasks. The target average CPU utilization is
60 percent.

Development uses a two-stage bootstrap because the ECR repository is initially
empty. First create the infrastructure with `ecs_desired_count = 0` and
`ecs_enable_autoscaling = false`. After CI/CD pushes and deploys the first valid
image, enable autoscaling and apply Terraform again. Terraform ignores later changes to the ECS desired count and task definition
because those values are owned by Application Auto Scaling and CI/CD.



## S3 archives and database backups

`environments/archive` owns a persistent, private, versioned, encrypted S3
bucket independently from the disposable dev and prod stacks. Create the
archive stack first; destroying dev or prod does not remove retained objects.

Application and VPC logs are retained under `logs/` for 30 days. Portable SQL
backups are retained under `backups/` for 90 days.

The application stack defines a one-off ECS Fargate task that creates a MySQL
dump from private RDS and uploads it with a dedicated least-privilege IAM role.
It does not run continuously.

See [`../../docs/S3_ARCHIVE_AND_BACKUP.md`](../../docs/S3_ARCHIVE_AND_BACKUP.md)
for deployment order, log export, database backup, and verification commands.
