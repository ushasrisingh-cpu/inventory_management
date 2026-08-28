variable "aws_region" {
  description = "AWS region for the environment."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "inventory-management"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones for public and private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, in AZ order."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, in AZ order."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "nat_gateway_strategy" {
  description = "Use one NAT Gateway for cost-aware dev or one per AZ for resilience."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_strategy)
    error_message = "nat_gateway_strategy must be single or per_az."
  }
}
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention period for VPC Flow Logs."
  type        = number
  default     = 30
}
variable "flow_logs_kms_key_arn" {
  description = "KMS key ARN used to encrypt the VPC Flow Logs CloudWatch group."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged with the standard project tags."
  type        = map(string)
  default     = {}
}

variable "ecr_repository_name" {
  description = "ECR repository name."
  type        = string
  default     = "inventory-management"
}

variable "ecr_image_retention_count" {
  description = "Number of tagged ECR images to retain."
  type        = number
  default     = 10
}

variable "ecr_kms_key_arn" {
  description = "KMS key ARN used to encrypt ECR images."
  type        = string
  default     = null
}

variable "eks_cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "inventory-management-dev"
}

variable "eks_kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}

variable "enable_public_eks_endpoint" {
  description = "Allow public access to the EKS API endpoint. Prefer false for production."
  type        = bool
  default     = false
}

variable "public_endpoint_cidrs" {
  description = "CIDRs allowed to access the public EKS API endpoint when enabled."
  type        = list(string)
  default     = []
}

variable "eks_cluster_log_types" {
  description = "EKS control-plane log types to publish to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_secrets_kms_key_arn" {
  description = "KMS key ARN used for EKS Kubernetes secret encryption."
  type        = string
  default     = null
}

variable "require_imdsv2" {
  description = "Require IMDSv2 for EKS worker nodes."
  type        = bool
  default     = true
}

variable "enable_github_oidc" {
  description = "Create the GitHub Actions OIDC provider and deployment role."
  type        = bool
  default     = false
}

variable "github_repository" {
  description = "GitHub repository in owner/name form for OIDC trust."
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "Git branch allowed to assume the GitHub OIDC role."
  type        = string
  default     = "master"
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_database_name" {
  description = "Initial RDS database name."
  type        = string
  default     = "inventory"
}

variable "rds_username" {
  description = "RDS master username."
  type        = string
  default     = "inventory_admin"
}

variable "rds_password" {
  description = "RDS master password. Supply through an uncommitted tfvars file or environment variable."
  type        = string
  sensitive   = true
}

variable "rds_engine_version" {
  description = "Optional MySQL engine version; null uses the provider default."
  type        = string
  default     = null
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Prevent accidental RDS deletion."
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip the RDS final snapshot on deletion."
  type        = bool
  default     = true
}

variable "rds_enable_performance_insights" {
  description = "Enable RDS Performance Insights."
  type        = bool
  default     = false
}

variable "rds_enable_enhanced_monitoring" {
  description = "Enable RDS Enhanced Monitoring."
  type        = bool
  default     = false
}

variable "rds_monitoring_interval" {
  description = "RDS Enhanced Monitoring interval in seconds; zero disables it."
  type        = number
  default     = 0
}

variable "rds_cloudwatch_log_exports" {
  description = "RDS log types exported to CloudWatch Logs."
  type        = list(string)
  default     = []
}

variable "rds_kms_key_arn" {
  description = "KMS key ARN used to encrypt RDS storage."
  type        = string
  default     = null
}
variable "rds_iam_database_authentication_enabled" {
  description = "Enable IAM database authentication for RDS."
  type        = bool
  default     = true
}
