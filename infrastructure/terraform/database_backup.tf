data "aws_partition" "current" {}

locals {
  archive_bucket_name = substr(
    lower("${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-archive"),
    0,
    63
  )
  archive_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${local.archive_bucket_name}"
}

resource "aws_iam_role" "database_backup" {
  name = "${var.project_name}-${var.environment}-database-backup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "database_backup_s3" {
  name = "${var.project_name}-${var.environment}-database-backup-s3"
  role = aws_iam_role.database_backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UploadDatabaseBackups"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = "${local.archive_bucket_arn}/backups/*"
      },
      {
        Sid      = "ReadArchiveBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = local.archive_bucket_arn
      }
    ]
  })
}

resource "aws_ecs_task_definition" "database_backup" {
  family                   = "${var.project_name}-${var.environment}-database-backup"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = module.iam.ecs_execution_role_arn
  task_role_arn            = aws_iam_role.database_backup.arn

  volume {
    name = "database-backup"
  }

  container_definitions = jsonencode([
    {
      name      = "database-dump"
      image     = "mysql:8.4"
      essential = false

      entryPoint = ["/bin/sh", "-c"]
      command = [
        "mysqldump --single-transaction --quick --skip-lock-tables --set-gtid-purged=OFF --no-tablespaces --host=\"$DB_HOST\" --port=\"$DB_PORT\" --user=\"$DB_USERNAME\" --password=\"$DB_PASSWORD\" \"$DB_NAME\" > /backup/inventory.sql"
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = module.rds.address
        },
        {
          name  = "DB_PORT"
          value = tostring(module.rds.port)
        },
        {
          name  = "DB_NAME"
          value = var.rds_database_name
        }
      ]

      secrets = [
        {
          name      = "DB_USERNAME"
          valueFrom = "${module.rds.managed_master_user_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${module.rds.managed_master_user_secret_arn}:password::"
        }
      ]

      mountPoints = [{
        sourceVolume  = "database-backup"
        containerPath = "/backup"
        readOnly      = false
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/${var.project_name}/${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "database-backup"
        }
      }
    },
    {
      name      = "backup-upload"
      image     = "public.ecr.aws/aws-cli/aws-cli:latest"
      essential = true

      dependsOn = [{
        containerName = "database-dump"
        condition     = "SUCCESS"
      }]

      entryPoint = ["/bin/sh", "-c"]
      command = [
        "aws s3 cp /backup/inventory.sql \"s3://$ARCHIVE_BUCKET/backups/$ENVIRONMENT/inventory-$(date -u +%Y%m%dT%H%M%SZ).sql\""
      ]

      environment = [
        {
          name  = "ARCHIVE_BUCKET"
          value = local.archive_bucket_name
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      mountPoints = [{
        sourceVolume  = "database-backup"
        containerPath = "/backup"
        readOnly      = true
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/${var.project_name}/${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "database-backup"
        }
      }
    }
  ])

  tags = local.common_tags
}

resource "aws_iam_role" "database_backup_scheduler" {
  count = var.enable_scheduled_database_backup ? 1 : 0

  name = "${var.project_name}-${var.environment}-database-backup-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule-group/default"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "database_backup_scheduler" {
  count = var.enable_scheduled_database_backup ? 1 : 0

  name = "${var.project_name}-${var.environment}-database-backup-scheduler"
  role = aws_iam_role.database_backup_scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "RunDatabaseBackupTask"
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = aws_ecs_task_definition.database_backup.arn
        Condition = {
          ArnEquals = {
            "ecs:cluster" = "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${module.ecs.cluster_name}"
          }
        }
      },
      {
        Sid    = "PassDatabaseBackupRoles"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          module.iam.ecs_execution_role_arn,
          aws_iam_role.database_backup.arn
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Sid    = "UseDatabaseBackupScheduleKey"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.platform.arn
      }
    ]
  })
}

resource "aws_scheduler_schedule" "database_backup" {
  count = var.enable_scheduled_database_backup ? 1 : 0

  name                = "${var.project_name}-${var.environment}-database-backup"
  description         = "Create a portable database backup and upload it to the persistent archive bucket."
  schedule_expression = var.database_backup_schedule_expression
  state               = "ENABLED"
  kms_key_arn         = aws_kms_key.platform.arn

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${module.ecs.cluster_name}"
    role_arn = aws_iam_role.database_backup_scheduler[0].arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.database_backup.arn
      launch_type         = "FARGATE"

      network_configuration {
        assign_public_ip = var.ecs_assign_public_ip
        security_groups  = [module.networking.task_security_group_id]
        subnets          = var.ecs_assign_public_ip ? module.networking.public_subnet_ids : module.networking.private_subnet_ids
      }
    }

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 2
    }
  }
}

output "database_backup_task_definition_arn" {
  value = aws_ecs_task_definition.database_backup.arn
}

output "task_security_group_id" {
  value = module.networking.task_security_group_id
}

output "archive_bucket_name" {
  value = local.archive_bucket_name
}
