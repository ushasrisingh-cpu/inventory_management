variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "project_name" {
  type    = string
  default = "inventory-management"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "availability_zones" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.11.0/24", "10.20.12.0/24"]
}
variable "enable_nat_gateway" {
  type    = bool
  default = false
}
variable "nat_gateway_strategy" {
  type    = string
  default = "single"
}
variable "enable_flow_logs" {
  type    = bool
  default = true
}
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "flow_logs_kms_key_arn" {
  type    = string
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "ecr_repository_name" {
  type    = string
  default = "inventory-management"
}
variable "ecr_image_retention_count" {
  type    = number
  default = 10
}
variable "ecr_kms_key_arn" {
  type    = string
  default = null
}
variable "ecs_container_name" {
  type    = string
  default = "inventory-management"
}
variable "ecs_image_tag" {
  type    = string
  default = "IMMUTABLE_IMAGE_TAG"
}
variable "ecs_cpu" {
  type    = number
  default = 256
}
variable "ecs_memory" {
  type    = number
  default = 512
}
variable "ecs_desired_count" {
  type    = number
  default = 0
}
variable "ecs_app_port" {
  type    = number
  default = 8080
}
variable "ecs_assign_public_ip" {
  type    = bool
  default = true
}
variable "ecs_log_retention_days" {
  type    = number
  default = 30
}
variable "ecs_health_check_path" {
  type    = string
  default = "/actuator/health/readiness"
}
variable "spring_profiles_active" {
  type    = string
  default = "prod"
}
variable "enable_github_oidc" {
  type    = bool
  default = false
}
variable "github_repository" {
  type    = string
  default = ""
}
variable "github_branch" {
  type    = string
  default = "master"
}
variable "rds_backup_retention_period" {
  type    = number
  default = 7
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "rds_database_name" {
  type    = string
  default = "inventory"
}
variable "rds_username" {
  type    = string
  default = "inventory_admin"
}
variable "rds_engine_version" {
  type    = string
  default = null
}
variable "rds_multi_az" {
  type    = bool
  default = false
}
variable "rds_deletion_protection" {
  type    = bool
  default = false
}
variable "rds_skip_final_snapshot" {
  type    = bool
  default = true
}
variable "rds_enable_performance_insights" {
  type    = bool
  default = false
}
variable "rds_enable_enhanced_monitoring" {
  type    = bool
  default = false
}
variable "rds_monitoring_interval" {
  type    = number
  default = 0
}
variable "rds_cloudwatch_log_exports" {
  type    = list(string)
  default = []
}
variable "rds_kms_key_arn" {
  type    = string
  default = null
}
