output "vpc_id" { value = module.networking.vpc_id }
output "public_subnet_ids" { value = module.networking.public_subnet_ids }
output "private_subnet_ids" { value = module.networking.private_subnet_ids }
output "ecr_repository_url" { value = module.ecr.repository_url }
output "ecs_cluster_name" { value = module.ecs.cluster_name }
output "ecs_service_name" { value = module.ecs.service_name }
output "alb_dns_name" { value = module.ecs.alb_dns_name }
output "rds_endpoint" { value = module.rds.endpoint }
output "managed_master_user_secret_arn" {
  value     = module.rds.managed_master_user_secret_arn
  sensitive = true
}
output "github_actions_role_arn" { value = module.iam.github_actions_role_arn }
output "platform_kms_key_arn" { value = aws_kms_key.platform.arn }
