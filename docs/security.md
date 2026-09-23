# Security Controls

## Implemented controls

| Layer | Control | Enforcement |
|---|---|---|
| Source history | Gitleaks | CI blocking |
| Application | Maven tests | CI blocking |
| Code analysis | SonarCloud Quality Gate | Enabled for reviewed changes |
| Container | Trivy high and critical fixable findings | CI blocking |
| Infrastructure | Terraform format and validate | CI blocking |
| Policy | Checkov for Terraform and Kubernetes | CI blocking with documented exceptions |
| Delivery identity | GitHub OIDC role | Short-lived credentials |
| Runtime identity | Separate ECS execution and task roles | Least privilege |
| Database | Private RDS and scoped security group | Network isolation |
| Secrets | AWS Secrets Manager and GitHub Secrets | No committed values |
| Storage | Encryption, S3 public-access block, secure transport, versioning | Terraform managed |

## Scan policy

Trivy fails on fixable high or critical image vulnerabilities. Gitleaks findings fail the workflow. Checkov failures block CI unless the repository records a specific accepted exception. Exceptions must describe the environment constraint or tool limitation and must be reviewed again for production.

## Secret handling

- RDS manages the database master secret.
- The ECS execution role reads only the required secret.
- GitHub OIDC avoids long-lived AWS access keys.
- Optional scanner tokens use GitHub Secrets.
- Non-sensitive configuration uses GitHub Variables.
- Logs and documentation must not contain secret values.

## Runtime controls

ALB, task, and RDS security groups restrict traffic by source security group and required port. ECS tasks have no inbound public rule. RDS remains private. CloudWatch receives application logs without requiring access to the application host.

## Future improvements

- Add OWASP ZAP against an approved temporary endpoint.
- Evaluate Snyk only after comparing overlap with existing controls.
- Add Security Hub, GuardDuty, AWS Config, and centralized CloudTrail for a production account.
- Configure production HTTPS with a domain and ACM certificate.
