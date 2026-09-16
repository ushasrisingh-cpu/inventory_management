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
        Resource = "${aws_s3_bucket.archive.arn}/backups/*"
      },
      {
        Sid      = "ReadArchiveBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.archive.arn
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
        "mysqldump --single-transaction --quick --lock-tables=false --host=\"$DB_HOST\" --port=\"$DB_PORT\" --user=\"$DB_USERNAME\" --password=\"$DB_PASSWORD\" \"$DB_NAME\" > /backup/inventory.sql"
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
          value = aws_s3_bucket.archive.bucket
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

output "database_backup_task_definition_arn" {
  value = aws_ecs_task_definition.database_backup.arn
}

output "task_security_group_id" {
  value = module.networking.task_security_group_id
}
