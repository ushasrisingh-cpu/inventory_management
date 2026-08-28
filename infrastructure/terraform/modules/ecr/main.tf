resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Retain recent tagged images for the capstone environment"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v", "sha-"]
        countType     = "imageCountMoreThan"
        countNumber   = var.image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}
