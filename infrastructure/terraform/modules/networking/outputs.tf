output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for subnet in aws_subnet.public : subnet.id] }
output "private_subnet_ids" { value = [for subnet in aws_subnet.private : subnet.id] }
output "alb_security_group_id" { value = aws_security_group.alb.id }
output "eks_cluster_security_group_id" { value = aws_security_group.eks_cluster.id }
output "eks_node_security_group_id" { value = aws_security_group.eks_node.id }
output "rds_security_group_id" { value = aws_security_group.rds.id }
