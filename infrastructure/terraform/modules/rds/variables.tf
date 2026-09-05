variable "identifier" { type = string }
variable "database_name" { type = string }
variable "username" { type = string }
variable "instance_class" { type = string }
variable "backup_retention_period" {
  type    = number
  default = 7
}
variable "engine_version" {
  type    = string
  default = null
}
variable "private_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "tags" { type = map(string) }
variable "multi_az" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "enable_performance_insights" {
  type    = bool
  default = false
}

variable "enable_enhanced_monitoring" {
  type    = bool
  default = false
}

variable "monitoring_interval" {
  type    = number
  default = 0
}

variable "cloudwatch_log_exports" {
  type    = list(string)
  default = []
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "iam_database_authentication_enabled" {
  type    = bool
  default = true
}
