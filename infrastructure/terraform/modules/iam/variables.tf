variable "project_name" { type = string }
variable "environment" { type = string }
variable "enable_github_oidc" { type = bool }
variable "github_repository" { type = string }
variable "github_branch" { type = string }
variable "ecr_repository_name" { type = string }
variable "eks_cluster_name" { type = string }
variable "tags" { type = map(string) }
