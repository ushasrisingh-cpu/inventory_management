#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-devsecops-terraform}"
AWS_REGION="${AWS_REGION:-ap-south-1}"
TF_ENVIRONMENT="${TF_ENVIRONMENT:-dev}"
TF_DIRECTORY="infrastructure/terraform/environments/${TF_ENVIRONMENT}"

terraform_output() {
  AWS_PROFILE="$AWS_PROFILE" terraform -chdir="$TF_DIRECTORY" output -raw "$1"
}

CLUSTER="$(terraform_output ecs_cluster_name)"
TASK_DEFINITION="$(terraform_output database_backup_task_definition_arn)"
SECURITY_GROUP="$(terraform_output task_security_group_id)"

if [[ "$TF_ENVIRONMENT" == "dev" ]]; then
  SUBNET_OUTPUT="public_subnet_ids"
  ASSIGN_PUBLIC_IP="ENABLED"
else
  SUBNET_OUTPUT="private_subnet_ids"
  ASSIGN_PUBLIC_IP="DISABLED"
fi

SUBNETS="$(
  AWS_PROFILE="$AWS_PROFILE" terraform -chdir="$TF_DIRECTORY" \
    output -json "$SUBNET_OUTPUT" |
    python3 -c 'import json,sys; print(",".join(json.load(sys.stdin)))'
)"

TASK_ARN="$(
  AWS_PROFILE="$AWS_PROFILE" aws ecs run-task \
    --region "$AWS_REGION" \
    --cluster "$CLUSTER" \
    --task-definition "$TASK_DEFINITION" \
    --launch-type FARGATE \
    --network-configuration \
      "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=$ASSIGN_PUBLIC_IP}" \
    --query 'tasks[0].taskArn' \
    --output text
)"

if [[ -z "$TASK_ARN" || "$TASK_ARN" == "None" ]]; then
  echo "Failed to start the database backup task." >&2
  exit 1
fi

echo "Started backup task: $TASK_ARN"
echo "Waiting for the backup task to stop..."

AWS_PROFILE="$AWS_PROFILE" aws ecs wait tasks-stopped \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER" \
  --tasks "$TASK_ARN"

AWS_PROFILE="$AWS_PROFILE" aws ecs describe-tasks \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER" \
  --tasks "$TASK_ARN" \
  --query 'tasks[0].{StoppedReason:stoppedReason,Containers:containers[].{Name:name,ExitCode:exitCode,Reason:reason}}' \
  --output json \
  --no-cli-pager
