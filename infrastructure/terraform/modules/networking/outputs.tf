output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for subnet in aws_subnet.public : subnet.id] }
output "private_subnet_ids" { value = [for subnet in aws_subnet.private : subnet.id] }
output "alb_security_group_id" { value = aws_security_group.alb.id }
output "task_security_group_id" { value = aws_security_group.task.id }
output "rds_security_group_id" { value = aws_security_group.rds.id }
