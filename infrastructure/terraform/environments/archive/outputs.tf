output "archive_bucket_name" {
  value = module.archive.archive_bucket_name
}

output "terraform_state_bucket" {
  value = module.archive.archive_bucket_name
}

output "platform_automation_role_arn" {
  value = aws_iam_role.platform_automation.arn
}

output "application_deploy_role_arn" {
  value = aws_iam_role.application_deploy.arn
}
