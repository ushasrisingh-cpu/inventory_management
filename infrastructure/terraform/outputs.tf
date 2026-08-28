output "vpc_id" {
  description = "VPC ID."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS and RDS."
  value       = module.networking.private_subnet_ids
}

output "ecr_repository_url" {
  description = "ECR repository URL."
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "RDS endpoint."
  value       = module.rds.endpoint
}

output "alb_security_group_id" {
  description = "Security group reserved for future ALB/Load Balancer Controller integration."
  value       = module.networking.alb_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID."
  value       = module.networking.eks_node_security_group_id
}

output "rds_security_group_id" {
  description = "RDS security group ID."
  value       = module.networking.rds_security_group_id
}

output "github_actions_role_arn" {
  description = "Optional GitHub Actions OIDC role ARN."
  value       = module.iam.github_actions_role_arn
}
output "platform_kms_key_arn" {
  description = "KMS key ARN used for platform encryption."
  value       = aws_kms_key.platform.arn
}
output "eks_oidc_provider_arn" {
  description = "ARN of the EKS IAM OIDC provider."
  value       = module.eks.oidc_provider_arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller."
  value       = module.eks.load_balancer_controller_role_arn
}
