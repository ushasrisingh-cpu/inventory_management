output "vpc_id" { value = module.infrastructure.vpc_id }
output "public_subnet_ids" { value = module.infrastructure.public_subnet_ids }
output "private_subnet_ids" { value = module.infrastructure.private_subnet_ids }
output "ecr_repository_url" { value = module.infrastructure.ecr_repository_url }
output "ecs_cluster_name" { value = module.infrastructure.ecs_cluster_name }
output "ecs_service_name" { value = module.infrastructure.ecs_service_name }
output "alb_dns_name" { value = module.infrastructure.alb_dns_name }
output "rds_endpoint" { value = module.infrastructure.rds_endpoint }
output "managed_master_user_secret_arn" {
  value     = module.infrastructure.managed_master_user_secret_arn
  sensitive = true
}
output "github_actions_role_arn" { value = module.infrastructure.github_actions_role_arn }
output "platform_kms_key_arn" { value = module.infrastructure.platform_kms_key_arn }
