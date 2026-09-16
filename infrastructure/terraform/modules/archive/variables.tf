variable "project_name" {
  type = string
}

variable "environments" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}
