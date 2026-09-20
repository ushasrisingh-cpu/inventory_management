data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  platform_role_name = "${var.project_name}-platform-github-actions"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = local.common_tags
}

resource "aws_iam_role" "platform_automation" {
  name = local.platform_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:ushasrisingh-cpu@318326122/inventory_management@1342675104:ref:refs/heads/${var.github_branch}",
            "repo:ushasrisingh-cpu@318326122/inventory_management@1342675104:environment:terraform-dev",
            "repo:ushasrisingh-cpu@318326122/inventory_management@1342675104:environment:terraform-prod"
          ]
        }
      }
    }]
  })

  tags = local.common_tags
}

#checkov:skip=CKV_AWS_109:The automation role needs bounded administrative actions for the regional platform resources it owns.
#checkov:skip=CKV_AWS_111:The workflow must create, update, read, and destroy the Terraform-managed regional platform resources.
#checkov:skip=CKV_AWS_290:Write access is restricted by region and IAM role-name prefix, while S3 access is restricted to Terraform state.
#checkov:skip=CKV_AWS_355:Some AWS create and discovery APIs do not support resource-level permissions; region and service restrictions provide the boundary.
resource "aws_iam_role_policy" "platform_automation" {
  name = "${var.project_name}-platform-automation"
  role = aws_iam_role.platform_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageRegionalPlatform"
        Effect = "Allow"
        Action = [
          "application-autoscaling:*",
          "cloudwatch:*",
          "ec2:*",
          "ecr:*",
          "ecs:*",
          "elasticloadbalancing:*",
          "kms:*",
          "logs:*",
          "rds:*",
          "scheduler:*",
          "secretsmanager:*",
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "ManageProjectRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
      },
      {
        Sid      = "CreateRequiredServiceLinkedRoles"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "ecs.amazonaws.com",
              "ecs.application-autoscaling.amazonaws.com",
              "elasticloadbalancing.amazonaws.com",
              "rds.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "ReadTerraformStateBucketMetadata"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = module.archive.archive_bucket_arn
      },
      {
        Sid      = "ListTerraformStatePrefix"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = module.archive.archive_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = ["terraform/*"]
          }
        }
      },
      {
        Sid    = "ManageTerraformStateObjects"
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${module.archive.archive_bucket_arn}/terraform/*"
      }
    ]
  })
}

resource "aws_iam_role" "application_deploy" {
  name = "${var.project_name}-application-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:ushasrisingh-cpu@318326122/inventory_management@1342675104:ref:refs/heads/${var.github_branch}"
        }
      }
    }]
  })

  tags = local.common_tags
}

#checkov:skip=CKV_AWS_290:The deployment role writes only to the project ECR repository and ECS resources.
#checkov:skip=CKV_AWS_355:ECR authorization and ECS task registration require wildcard resources; other write actions are project scoped.
resource "aws_iam_role_policy" "application_deploy" {
  name = "${var.project_name}-application-deploy"
  role = aws_iam_role.application_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AuthenticateToECR"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "PushProjectImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}"
      },
      {
        Sid    = "ReadAndRegisterTaskDefinitions"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "DeployProjectServices"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:UpdateService"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-*/*",
          "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task/${var.project_name}-*/*"
        ]
      },
      {
        Sid      = "PassProjectTaskRoles"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}
