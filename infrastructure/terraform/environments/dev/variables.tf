variable "aws_region" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zones" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "tags" { type = map(string) }
variable "ecr_repository_name" { type = string }
variable "ecr_image_retention_count" { type = number }
variable "eks_cluster_name" { type = string }
variable "eks_kubernetes_version" { type = string }
variable "eks_node_instance_types" { type = list(string) }
variable "eks_node_desired_size" { type = number }
variable "eks_node_min_size" { type = number }
variable "eks_node_max_size" { type = number }
variable "enable_github_oidc" { type = bool }
variable "github_repository" { type = string }
variable "github_branch" { type = string }
variable "rds_instance_class" { type = string }
variable "rds_database_name" { type = string }
variable "rds_username" { type = string }
variable "rds_password" {
  type      = string
  sensitive = true
}
variable "rds_engine_version" { type = string }
