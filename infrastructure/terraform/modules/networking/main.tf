resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.project_name}-${var.environment}-vpc" })
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-default-sg"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-${var.environment}-igw" })
}

resource "aws_subnet" "public" {
  for_each = { for index, az in var.availability_zones : az => index }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = var.public_subnet_cidrs[each.value]
  map_public_ip_on_launch = false
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = { for index, az in var.availability_zones : az => index }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = var.private_subnet_cidrs[each.value]
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-public-rt" })
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.project_name}-${var.environment}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id
  depends_on    = [aws_internet_gateway.this]
  tags          = merge(var.tags, { Name = "${var.project_name}-${var.environment}-nat" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[var.nat_gateway_strategy == "per_az" ? each.value : 0].id
    }
  }
  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-private-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5: This security group is attached to the ALB in the sibling ECS module.
  name        = "${var.project_name}-${var.environment}-alb"
  description = "Ingress boundary reserved for the ECS application load balancer."
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.project_name}-${var.environment}-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260: Port 80 is the intentional public entry point for the temporary demo ALB.
  description       = "Allow public HTTP traffic to the ALB."
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}



resource "aws_security_group" "task" {
  #checkov:skip=CKV2_AWS_5: This security group is attached to the ECS service in the sibling ECS module.
  name        = "${var.project_name}-${var.environment}-task"
  description = "ECS task security boundary."
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.project_name}-${var.environment}-task-sg" })
}
resource "aws_vpc_security_group_ingress_rule" "task_app" {
  description                  = "Allow application traffic from the ALB to ECS tasks."
  security_group_id            = aws_security_group.task.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}
resource "aws_security_group" "rds" {
  #checkov:skip=CKV2_AWS_5: This security group is attached to RDS in the sibling RDS module.
  name        = "${var.project_name}-${var.environment}-rds"
  description = "Private MySQL security boundary."
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.project_name}-${var.environment}-rds-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql" {
  description                  = "Allow MySQL traffic from ECS tasks."
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.task.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}
resource "aws_vpc_security_group_egress_rule" "alb_to_task" {
  description                  = "Allow the ALB to reach ECS tasks on the application port."
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.task.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "task_https" {
  description       = "Allow ECS tasks to reach AWS APIs and pull images over HTTPS."
  security_group_id = aws_security_group.task.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "task_dns_udp" {
  description       = "Allow ECS tasks to resolve DNS over UDP inside the VPC."
  security_group_id = aws_security_group.task.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  ip_protocol       = "udp"
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "task_dns_tcp" {
  description       = "Allow ECS tasks to resolve DNS over TCP inside the VPC."
  security_group_id = aws_security_group.task.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  ip_protocol       = "tcp"
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "task_mysql" {
  description                  = "Allow ECS tasks to connect to the private RDS database."
  security_group_id            = aws_security_group.task.id
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}
