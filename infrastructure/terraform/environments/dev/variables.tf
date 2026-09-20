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
variable "enable_github_oidc" { type = bool }
variable "github_repository" { type = string }
variable "github_branch" { type = string }
variable "rds_backup_retention_period" {
  type    = number
  default = 1
}
variable "rds_instance_class" { type = string }
variable "rds_database_name" { type = string }
variable "rds_username" { type = string }
variable "rds_engine_version" { type = string }

variable "enable_nat_gateway" { type = bool }
variable "enable_flow_logs" { type = bool }
variable "log_retention_days" { type = number }
variable "flow_logs_kms_key_arn" {
  type    = string
  default = null
}
variable "ecr_kms_key_arn" { type = string }
variable "ecs_container_name" { type = string }
variable "ecs_image_tag" { type = string }
variable "ecs_cpu" { type = number }
variable "ecs_memory" { type = number }
variable "ecs_desired_count" { type = number }
variable "ecs_enable_autoscaling" {
  type    = bool
  default = false
}

variable "ecs_autoscaling_min_capacity" {
  type    = number
  default = 1
}

variable "ecs_autoscaling_max_capacity" {
  type    = number
  default = 2
}

variable "ecs_autoscaling_target_cpu_utilization" {
  type    = number
  default = 60
}

variable "ecs_autoscaling_target_request_count" {
  type    = number
  default = 1000
}

variable "ecs_autoscaling_scale_in_cooldown" {
  type    = number
  default = 120
}

variable "ecs_autoscaling_scale_out_cooldown" {
  type    = number
  default = 60
}
variable "ecs_app_port" { type = number }
variable "ecs_assign_public_ip" { type = bool }
variable "ecs_log_retention_days" { type = number }
variable "ecs_health_check_path" { type = string }
variable "spring_profiles_active" { type = string }

variable "enable_scheduled_database_backup" {
  type    = bool
  default = true
}

variable "database_backup_schedule_expression" {
  type    = string
  default = "cron(0 2 * * ? *)"
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
variable "nat_gateway_strategy" { type = string }
