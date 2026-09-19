# Troubleshooting Guide

## Diagnostic method

Start with the failing layer and use commands that do not print secrets. Record the symptom, relevant timestamps, resource name, and corrective action.

| Symptom | Likely cause | Diagnostic action | Corrective action |
|---|---|---|---|
| Maven compilation fails | Java or dependency mismatch | Check `java -version` and Maven output | Use Java 17 and review the first compiler error |
| Tests fail | Code or test-data regression | Run the failing test locally | Fix the cause before packaging |
| Port 8080 unavailable | Another local process is listening | Inspect local listeners | Stop the conflicting process or configure another port |
| Application cannot reach MySQL | Profile, DNS, credential, or security-group issue | Review sanitized application logs and network rules | Correct configuration without printing the password |
| Docker container exits | Startup configuration or database unavailable | Inspect container exit status and logs | Supply the required profile and settings |
| Terraform init fails | Backend, provider, network, or credential problem | Run init in the intended directory | Reauthenticate or correct backend/provider configuration |
| Saved plan is stale | Terraform state changed after plan creation | Create a new plan | Never apply the stale file |
| Checkov fails | Policy violation or stale exception | Inspect failed check and resource | Fix the design or document a narrowly reviewed skip |
| Trivy fails | Fixable high or critical package finding | Review the package and fixed version | Update base image or dependency, then rebuild |
| ECS task will not start | Image, secret, IAM, CPU/memory, or configuration issue | Inspect ECS stopped-task reason and CloudWatch logs | Correct the failing resource and redeploy |
| ALB times out | Listener, target health, routing, or security group | Check target health and readiness internally | Correct health path or network rules |
| CD fails after dev teardown | Deployment target no longer exists | Check `DEV_INFRA_ENABLED` | Set it to `false` while dev is offline |
| AWS CLI session expired | Temporary login expired | Run a caller-identity check | Reauthenticate the underlying profile |
| Backup dump fails on table lock | RDS user lacks global lock privilege | Inspect backup log stream | Use the RDS-compatible dump options documented in code |
| CloudWatch export task reports KMS deletion | Export service rejects historical KMS association | Verify current keys and log group | Use the direct read, gzip, and S3 archive script |
| S3 destroy fails | Bucket contains retained versions | List objects and versions | Preserve or deliberately remove data before archive destruction |

## Escalation

Do not weaken IAM, expose RDS, disable security gates, or delete retained data to bypass a failure. Capture sanitized evidence, stop the deployment, and request review when ownership or impact is unclear.
