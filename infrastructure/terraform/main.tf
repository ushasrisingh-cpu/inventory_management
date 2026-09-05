locals {
  common_tags                = merge({ Project = var.project_name, Environment = var.environment, ManagedBy = "Terraform" }, var.tags)
  ecs_cluster_name           = "${var.project_name}-${var.environment}"
  ecs_service_name           = "${var.project_name}-${var.environment}"
  ecs_task_definition_family = "${var.project_name}-${var.environment}"
}
module "networking" {
  source                = "./modules/networking"
  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  enable_nat_gateway    = var.enable_nat_gateway
  nat_gateway_strategy  = var.nat_gateway_strategy
  enable_flow_logs      = var.enable_flow_logs
  log_retention_days    = var.log_retention_days
  flow_logs_kms_key_arn = coalesce(var.flow_logs_kms_key_arn, aws_kms_key.platform.arn)
  tags                  = local.common_tags
}
module "iam" {
  source                     = "./modules/iam"
  project_name               = var.project_name
  environment                = var.environment
  enable_github_oidc         = var.enable_github_oidc
  github_repository          = var.github_repository
  github_branch              = var.github_branch
  ecr_repository_name        = var.ecr_repository_name
  ecs_cluster_name           = local.ecs_cluster_name
  ecs_service_name           = local.ecs_service_name
  ecs_task_definition_family = local.ecs_task_definition_family
  rds_secret_arn             = module.rds.managed_master_user_secret_arn
  platform_kms_key_arn       = aws_kms_key.platform.arn
  log_group_arn              = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/${var.project_name}/${var.environment}"
  tags                       = local.common_tags
}
module "ecr" {
  source                = "./modules/ecr"
  repository_name       = var.ecr_repository_name
  image_retention_count = var.ecr_image_retention_count
  kms_key_arn           = coalesce(var.ecr_kms_key_arn, aws_kms_key.platform.arn)
  tags                  = local.common_tags
}
module "rds" {
  source                      = "./modules/rds"
  identifier                  = "${var.project_name}-${var.environment}"
  database_name               = var.rds_database_name
  username                    = var.rds_username
  instance_class              = var.rds_instance_class
  backup_retention_period     = var.rds_backup_retention_period
  engine_version              = var.rds_engine_version
  private_subnet_ids          = module.networking.private_subnet_ids
  security_group_id           = module.networking.rds_security_group_id
  multi_az                    = var.rds_multi_az
  deletion_protection         = var.rds_deletion_protection
  skip_final_snapshot         = var.rds_skip_final_snapshot
  enable_performance_insights = var.rds_enable_performance_insights
  enable_enhanced_monitoring  = var.rds_enable_enhanced_monitoring
  monitoring_interval         = var.rds_monitoring_interval
  cloudwatch_log_exports      = var.rds_cloudwatch_log_exports
  kms_key_arn                 = coalesce(var.rds_kms_key_arn, aws_kms_key.platform.arn)
  tags                        = local.common_tags
}
module "ecs" {
  source                 = "./modules/ecs"
  project_name           = var.project_name
  environment            = var.environment
  cluster_name           = local.ecs_cluster_name
  service_name           = local.ecs_service_name
  task_definition_family = local.ecs_task_definition_family
  container_name         = var.ecs_container_name
  image                  = "${module.ecr.repository_url}:${var.ecs_image_tag}"
  cpu                    = var.ecs_cpu
  memory                 = var.ecs_memory
  desired_count          = var.ecs_desired_count
  app_port               = var.ecs_app_port
  public_subnet_ids      = module.networking.public_subnet_ids
  private_subnet_ids     = module.networking.private_subnet_ids
  alb_security_group_id  = module.networking.alb_security_group_id
  task_security_group_id = module.networking.task_security_group_id
  execution_role_arn     = module.iam.ecs_execution_role_arn
  task_role_arn          = module.iam.ecs_task_role_arn
  log_retention_days     = var.ecs_log_retention_days
  health_check_path      = var.ecs_health_check_path
  log_kms_key_arn        = aws_kms_key.platform.arn
  rds_address            = module.rds.address
  rds_port               = module.rds.port
  rds_database_name      = var.rds_database_name
  rds_managed_secret_arn = module.rds.managed_master_user_secret_arn
  spring_profiles_active = var.spring_profiles_active
  assign_public_ip       = var.ecs_assign_public_ip
  tags                   = local.common_tags
}
