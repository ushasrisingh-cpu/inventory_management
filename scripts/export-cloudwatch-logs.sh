#!/usr/bin/env bash
set -euo pipefail

LOG_GROUP="${1:?Usage: $0 LOG_GROUP [DESTINATION_PREFIX] [DAYS]}"
DESTINATION_PREFIX="${2:-logs/manual}"
DAYS="${3:-1}"

AWS_PROFILE="${AWS_PROFILE:-devsecops-terraform}"
AWS_REGION="${AWS_REGION:-ap-south-1}"
TF_ENVIRONMENT="${TF_ENVIRONMENT:-dev}"
TF_DIRECTORY="infrastructure/terraform/environments/${TF_ENVIRONMENT}"

BUCKET="$(
  AWS_PROFILE="$AWS_PROFILE" terraform -chdir="$TF_DIRECTORY" \
    output -raw archive_bucket_name
)"

# CloudWatch logs can take up to 12 hours to become exportable.
TO_MILLISECONDS="$(
  date -u -d '12 hours ago' +%s
)000"

FROM_MILLISECONDS="$(
  date -u -d "12 hours ago - ${DAYS} days" +%s
)000"

TASK_NAME="inventory-${TF_ENVIRONMENT}-$(date -u +%Y%m%dT%H%M%SZ)"

TASK_ID="$(
  AWS_PROFILE="$AWS_PROFILE" aws logs create-export-task \
    --region "$AWS_REGION" \
    --task-name "$TASK_NAME" \
    --log-group-name "$LOG_GROUP" \
    --from "$FROM_MILLISECONDS" \
    --to "$TO_MILLISECONDS" \
    --destination "$BUCKET" \
    --destination-prefix "$DESTINATION_PREFIX" \
    --query taskId \
    --output text
)"

echo "Started export task: $TASK_ID"
echo "Destination: s3://$BUCKET/$DESTINATION_PREFIX/"

while true; do
  STATUS="$(
    AWS_PROFILE="$AWS_PROFILE" aws logs describe-export-tasks \
      --region "$AWS_REGION" \
      --task-id "$TASK_ID" \
      --query 'exportTasks[0].status.code' \
      --output text
  )"

  echo "Export status: $STATUS"

  case "$STATUS" in
    COMPLETED)
      exit 0
      ;;
    FAILED|CANCELLED)
      exit 1
      ;;
  esac

  sleep 15
done
