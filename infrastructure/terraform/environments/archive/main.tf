locals {
  common_tags = merge(var.tags, {
    Project   = var.project_name
    ManagedBy = "Terraform"
    Purpose   = "Persistent archive"
  })
}

module "archive" {
  source = "../../modules/archive"

  project_name = var.project_name
  environments = var.environments
  tags         = local.common_tags
}
