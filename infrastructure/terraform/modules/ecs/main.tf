resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${var.project_name}/${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn
  tags              = var.tags
}

resource "aws_lb" "this" {
  enable_deletion_protection = var.environment == "prod"
  #checkov:skip=CKV_AWS_150: Deletion protection is disabled for disposable dev; production enables it by policy.
  #checkov:skip=CKV_AWS_91: ALB access logging is omitted for the short-lived cost-controlled dev deployment.
  #checkov:skip=CKV2_AWS_20: HTTPS redirect requires a validated domain and ACM certificate not available for this demo.
  #checkov:skip=CKV2_AWS_28: WAF is omitted for the short-lived cost-controlled dev deployment.
  name                       = substr("${var.project_name}-${var.environment}-alb", 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  subnets                    = var.public_subnet_ids
  security_groups            = [var.alb_security_group_id]
  tags                       = var.tags
}

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378: HTTP is used only between the ALB and isolated ECS tasks.
  name        = substr("${var.project_name}-${var.environment}-tg", 0, 32)
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_subnet.public.vpc_id
  health_check {
    enabled  = true
    path     = var.health_check_path
    matcher  = "200-399"
    protocol = "HTTP"
  }
  tags = var.tags
}

data "aws_subnet" "public" {
  id = var.public_subnet_ids[0]
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2: HTTP is temporary until a domain and ACM certificate are available.
  #checkov:skip=CKV_AWS_103: TLS policy is not applicable to the temporary HTTP-only listener.
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.task_definition_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions = jsonencode([{
    name         = var.container_name
    image        = var.image
    essential    = true
    portMappings = [{ containerPort = var.app_port, hostPort = var.app_port, protocol = "tcp" }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = var.spring_profiles_active },
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:mysql://${var.rds_address}:${var.rds_port}/${var.rds_database_name}?sslMode=REQUIRED" }
    ]
    secrets = [
      { name = "SPRING_DATASOURCE_USERNAME", valueFrom = "${var.rds_managed_secret_arn}:username::" },
      { name = "SPRING_DATASOURCE_PASSWORD", valueFrom = "${var.rds_managed_secret_arn}:password::" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  runtime_platform { operating_system_family = "LINUX" }
  tags = var.tags
}

data "aws_region" "current" {}

resource "aws_ecs_service" "this" {
  name                   = var.service_name
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  platform_version       = "LATEST"
  enable_execute_command = false
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.task_security_group_id]
    assign_public_ip = var.assign_public_ip
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.app_port
  }
  depends_on = [aws_lb_listener.http]
  tags       = var.tags
}
