# Terraform infrastructure

This stack deploys an ECS Fargate application in `ap-south-1` (Mumbai): VPC public and private subnets, encrypted ECR, platform KMS, optional Flow Logs, private encrypted MySQL RDS, a public HTTP ALB, and optional scoped GitHub Actions OIDC. ECS uses Fargate `awsvpc`, container port `8080`, IP targets, a configurable `/actuator/health/readiness` check, encrypted CloudWatch logs, deployment rollback, and ECS Exec disabled. RDS creates the encrypted master secret through AWS Secrets Manager; Terraform accepts no database password.

Dev uses `ecs_desired_count = 0`, `enable_nat_gateway = false`, and public task IPs so an image can be pushed before starting tasks. Prod uses private tasks (`ecs_assign_public_ip = false`), per-AZ NAT, Multi-AZ RDS, deletion protection, final snapshots, Performance Insights, Enhanced Monitoring, and longer log retention.

Root and environment outputs provide the ECR repository URL, ECS cluster and service names, ALB DNS name, RDS endpoint, sensitive managed secret ARN, GitHub role ARN, and platform KMS ARN. The ECS execution role is scoped to the ECR repository, ECS log group, managed RDS secret, and platform key.

Use the Mumbai examples in `terraform.tfvars.example` and `environments/*/terraform.tfvars.example`. Do not run `terraform apply`, deploy, initialize, validate, or Checkov as part of this migration.
