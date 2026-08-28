variable "repository_name" { type = string }
variable "image_retention_count" { type = number }
variable "kms_key_arn" { type = string }
variable "tags" { type = map(string) }
