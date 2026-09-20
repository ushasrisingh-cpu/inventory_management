variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "inventory-management"
}

variable "environments" {
  type    = list(string)
  default = ["dev", "prod"]
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the platform automation role, in owner/repository format."
  type        = string
}

variable "github_branch" {
  description = "Git branch allowed to run infrastructure plans."
  type        = string
  default     = "master"
}

variable "tags" {
  type    = map(string)
  default = {}
}
