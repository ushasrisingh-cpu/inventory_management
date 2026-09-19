# Cost and Cleanup

## Main cost drivers

- Amazon RDS instance and storage
- Application Load Balancer hours and capacity units
- ECS Fargate task CPU and memory
- NAT gateways in production configuration
- CloudWatch log ingestion and retention
- ECR and S3 storage
- Secrets Manager secrets
- KMS keys
- Data transfer

## Cost-conscious decisions

- ECS Fargate replaced EKS for the single-service cloud runtime.
- Dev avoids a NAT gateway and uses public task IPs with restricted inbound rules.
- Dev uses one application task until autoscaling requires another.
- Log and image retention policies limit storage growth.
- The dev environment is destroyed after bounded tests.
- The small persistent archive remains because recovery evidence has a different lifecycle.

## Safe dev cleanup

1. Set the GitHub variable `DEV_INFRA_ENABLED=false`.
2. Archive required logs.
3. Run and verify the portable database backup when required.
4. Confirm the backup can be listed and has encryption and a version ID.
5. Create a Terraform dev destroy plan.
6. Confirm no archive S3 resource appears in that plan.
7. Apply the saved dev destroy plan.
8. Confirm the dev Terraform state is empty.
9. Confirm S3 backup and log objects still exist.

## Archive cleanup

Do not destroy the archive during normal dev cleanup. The bucket uses `force_destroy=false`, so retained content blocks accidental deletion. Logs expire after 30 days and portable database backups after 90 days. Destroy the archive only after an explicit ownership and retention review.

## Remaining cost

After dev teardown, the archive bucket and retained objects continue to incur small S3 charges. KMS keys from destroyed environments may remain scheduled for deletion for their safety window. Review the AWS billing dashboard and resource inventory after each experiment.
