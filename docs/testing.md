# Testing and Validation Evidence

## Test strategy

Validation covered application build, infrastructure syntax and policy, container security, live AWS behavior, performance, autoscaling, backup, restore, logging, and teardown.

## Evidence summary

| Area | Method | Verified outcome |
|---|---|---|
| Java application | Maven CI | Tests and package jobs succeeded |
| Docker | CI image build | Image built successfully |
| Secret detection | Gitleaks | CI succeeded |
| Terraform | Format, init, validate | Root and environments valid |
| Infrastructure policy | Checkov | 185 passed, 0 failed, 29 skipped |
| Container security | Trivy | CI gate succeeded |
| Health | ALB readiness request | HTTP 200 and `UP` |
| Load | ApacheBench | 7,507 requests, 0 failures, 24.76 requests/second |
| Autoscaling | CPU load and AWS activity history | 1 to 2 tasks, then 2 to 1 |
| Database backup | One-off Fargate task | Both containers exit code 0 |
| S3 object | Object metadata | AES256, versioned, nonzero size |
| Database restore | Temporary MySQL 8.4 | 8 tables, 4 members, 8 products |
| Application log archive | Direct CloudWatch read to compressed S3 object | 5,005-byte object retained |
| VPC flow archive | Direct CloudWatch read to compressed S3 object | 43,525-byte object retained |
| Teardown | Terraform destroy and state check | 50 destroyed, dev state empty |

## Autoscaling evidence

The ECS service target-tracking policy used average CPU utilization with a 60 percent target, minimum one task, and maximum two tasks. CPU exceeded the target during the load test. Application Auto Scaling successfully set desired count to two. After the low alarm evaluation period, it set desired count back to one.

## Recovery evidence

The first `mysqldump` attempt exposed an RDS privilege constraint. The reviewed command added `--skip-lock-tables`, `--set-gtid-purged=OFF`, and `--no-tablespaces`. The next task succeeded. The SQL file was restored into an isolated temporary MySQL container and record counts were verified before cleanup.

## Limitations

The performance test demonstrates behavior for the temporary dev configuration, not a production capacity limit. Production Terraform was validated but not applied. Sonar is conditional, and Snyk and ZAP were not implemented.
