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

variable "tags" {
  type    = map(string)
  default = {}
}
