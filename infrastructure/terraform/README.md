# Terraform infrastructure

This stack defines the planned AWS foundation for the Inventory Management System: a VPC, private EKS worker nodes, KMS-backed ECR, encrypted private RDS MySQL, VPC Flow Logs, and optional GitHub Actions OIDC. The Kubernetes AWS Load Balancer Controller will manage the application ALB later; this Terraform code only prepares the ALB security boundary and does not create a standalone load balancer.

The `environments/dev` and `environments/prod` directories reuse the same root modules. Dev uses one NAT Gateway, smaller nodes, Single-AZ RDS, and shorter log retention. Prod uses one NAT Gateway per AZ, larger node capacity, Multi-AZ RDS, deletion protection, final snapshots, Performance Insights, Enhanced Monitoring, and longer log retention. Both environments keep private worker nodes, private RDS, encryption, Flow Logs, IMDSv2, and control-plane logging enabled.

Copy the relevant example variables file to an untracked `.tfvars` file and provide `rds_password` through `TF_VAR_rds_password` or another secret-aware mechanism. AWS credentials are intentionally not configured in Terraform; use the AWS CLI environment/profile locally or GitHub Actions OIDC.

The later Kubernetes layer should use a shared base with separate `dev` and `prod` overlays. Each overlay can select its namespace, immutable image tag, database endpoint, runtime Secret references, and HTTPS Ingress host while reusing the common application Deployment and Service definitions. The Ingress will use the public subnet tags and AWS Load Balancer Controller role prepared by this stack; the EKS API endpoint remains an independent, private administrative interface.

Validation commands:

```text
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan -var-file=environments/dev/terraform.tfvars
checkov -d infrastructure/terraform
```

Do not run `terraform apply` until the plan, security findings, network cost, and secret management have been reviewed. The dev defaults use one NAT Gateway, small EKS nodes, and a small RDS instance to control capstone cost. Destroy temporary environments after testing through an explicitly reviewed Terraform workflow.
