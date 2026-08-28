locals {
  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }, var.tags)
}

module "networking" {
  source = "./modules/networking"

  project_name          = var.project_name
  environment           = var.environment
  eks_cluster_name      = var.eks_cluster_name
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  nat_gateway_strategy  = var.nat_gateway_strategy
  enable_flow_logs      = var.enable_flow_logs
  log_retention_days    = var.log_retention_days
  flow_logs_kms_key_arn = coalesce(var.flow_logs_kms_key_arn, aws_kms_key.platform.arn)
  tags                  = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  enable_github_oidc  = var.enable_github_oidc
  github_repository   = var.github_repository
  github_branch       = var.github_branch
  ecr_repository_name = var.ecr_repository_name
  eks_cluster_name    = var.eks_cluster_name
  tags                = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  repository_name       = var.ecr_repository_name
  image_retention_count = var.ecr_image_retention_count
  kms_key_arn           = aws_kms_key.platform.arn
  tags                  = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name              = var.eks_cluster_name
  kubernetes_version        = var.eks_kubernetes_version
  private_subnet_ids        = module.networking.private_subnet_ids
  cluster_role_arn          = module.iam.eks_cluster_role_arn
  node_role_arn             = module.iam.eks_node_role_arn
  cluster_security_group_id = module.networking.eks_cluster_security_group_id
  node_security_group_id    = module.networking.eks_node_security_group_id
  node_instance_types       = var.eks_node_instance_types
  desired_size              = var.eks_node_desired_size
  min_size                  = var.eks_node_min_size
  max_size                  = var.eks_node_max_size
  enable_public_endpoint    = var.enable_public_eks_endpoint
  public_endpoint_cidrs     = var.public_endpoint_cidrs
  cluster_log_types         = var.eks_cluster_log_types
  secrets_kms_key_arn       = aws_kms_key.platform.arn
  require_imdsv2            = var.require_imdsv2
  tags                      = local.common_tags
}

module "rds" {
  source = "./modules/rds"

  identifier                          = "${var.project_name}-${var.environment}"
  database_name                       = var.rds_database_name
  username                            = var.rds_username
  password                            = var.rds_password
  instance_class                      = var.rds_instance_class
  engine_version                      = var.rds_engine_version
  private_subnet_ids                  = module.networking.private_subnet_ids
  security_group_id                   = module.networking.rds_security_group_id
  multi_az                            = var.rds_multi_az
  deletion_protection                 = var.rds_deletion_protection
  skip_final_snapshot                 = var.rds_skip_final_snapshot
  enable_performance_insights         = var.rds_enable_performance_insights
  enable_enhanced_monitoring          = var.rds_enable_enhanced_monitoring
  monitoring_interval                 = var.rds_monitoring_interval
  cloudwatch_log_exports              = var.rds_cloudwatch_log_exports
  kms_key_arn                         = coalesce(var.rds_kms_key_arn, aws_kms_key.platform.arn)
  iam_database_authentication_enabled = var.rds_iam_database_authentication_enabled
  tags                                = local.common_tags
}
