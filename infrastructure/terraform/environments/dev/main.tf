module "infrastructure" {
  source = "../.."

  aws_region                = var.aws_region
  project_name              = var.project_name
  environment               = var.environment
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs      = var.private_subnet_cidrs
  ecr_repository_name       = var.ecr_repository_name
  ecr_image_retention_count = var.ecr_image_retention_count
  eks_cluster_name          = var.eks_cluster_name
  eks_kubernetes_version    = var.eks_kubernetes_version
  eks_node_instance_types   = var.eks_node_instance_types
  eks_node_desired_size     = var.eks_node_desired_size
  eks_node_min_size         = var.eks_node_min_size
  eks_node_max_size         = var.eks_node_max_size
  enable_github_oidc        = var.enable_github_oidc
  github_repository         = var.github_repository
  github_branch             = var.github_branch
  rds_instance_class        = var.rds_instance_class
  rds_database_name         = var.rds_database_name
  rds_username              = var.rds_username
  rds_password              = var.rds_password
  rds_engine_version        = var.rds_engine_version
  tags                      = var.tags
}
