resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.identifier}-db-subnets" })
}

resource "aws_db_instance" "this" {
  identifier                          = var.identifier
  engine                              = "mysql"
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  allocated_storage                   = 20
  max_allocated_storage               = 50
  storage_type                        = "gp3"
  storage_encrypted                   = true
  db_name                             = var.database_name
  username                            = var.username
  password                            = var.password
  port                                = 3306
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [var.security_group_id]
  publicly_accessible                 = false
  multi_az                            = var.multi_az
  backup_retention_period             = 7
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.skip_final_snapshot ? null : "${var.identifier}-final"
  apply_immediately                   = false
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true
  kms_key_id                          = var.kms_key_arn
  performance_insights_enabled        = var.enable_performance_insights
  performance_insights_kms_key_id     = var.enable_performance_insights ? var.kms_key_arn : null
  enabled_cloudwatch_logs_exports     = var.cloudwatch_log_exports
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  monitoring_interval                 = var.enable_enhanced_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn                 = var.enable_enhanced_monitoring ? aws_iam_role.enhanced_monitoring[0].arn : null
  tags                                = var.tags
}
