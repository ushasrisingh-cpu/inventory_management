variable "project_name" { type = string }
variable "environment" { type = string }
variable "cluster_name" { type = string }
variable "service_name" { type = string }
variable "task_definition_family" { type = string }
variable "container_name" { type = string }
variable "image" { type = string }
variable "cpu" { type = number }
variable "memory" { type = number }
variable "desired_count" { type = number }
variable "app_port" { type = number }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "task_security_group_id" { type = string }
variable "execution_role_arn" { type = string }
variable "task_role_arn" { type = string }
variable "log_retention_days" { type = number }
variable "health_check_path" { type = string }
variable "log_kms_key_arn" { type = string }
variable "rds_address" { type = string }
variable "rds_port" { type = number }
variable "rds_database_name" { type = string }
variable "rds_managed_secret_arn" { type = string }
variable "spring_profiles_active" { type = string }
variable "assign_public_ip" { type = bool }
variable "tags" { type = map(string) }
variable "enable_autoscaling" {
  type    = bool
  default = false
}

variable "autoscaling_min_capacity" {
  type    = number
  default = 1
}

variable "autoscaling_max_capacity" {
  type    = number
  default = 3
}

variable "autoscaling_target_cpu_utilization" {
  type    = number
  default = 60
}

variable "autoscaling_target_request_count" {
  type    = number
  default = 1000
}

variable "autoscaling_scale_in_cooldown" {
  type    = number
  default = 120
}

variable "autoscaling_scale_out_cooldown" {
  type    = number
  default = 60
}
