#!/usr/bin/env bash
set -euo pipefail

LOG_GROUP="${1:?Usage: $0 LOG_GROUP [DESTINATION_PREFIX] [DAYS]}"
DESTINATION_PREFIX="${2:-logs/manual}"
DAYS="${3:-1}"

AWS_PROFILE="${AWS_PROFILE:-devsecops-terraform}"
AWS_REGION="${AWS_REGION:-ap-south-1}"
ARCHIVE_TF_DIRECTORY="${ARCHIVE_TF_DIRECTORY:-infrastructure/terraform/environments/archive}"

BUCKET="$(
  AWS_PROFILE="$AWS_PROFILE" \
  terraform -chdir="$ARCHIVE_TF_DIRECTORY" \
  output -raw archive_bucket_name
)"

FROM_MILLISECONDS="$(date -u -d "$DAYS days ago" +%s)000"
TO_MILLISECONDS="$(date -u +%s)000"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE_FILE="$(mktemp --suffix=.json.gz)"

trap 'rm -f "$ARCHIVE_FILE"' EXIT

echo "Reading CloudWatch logs from: $LOG_GROUP"

AWS_PROFILE="$AWS_PROFILE" aws logs filter-log-events \
  --region "$AWS_REGION" \
  --log-group-name "$LOG_GROUP" \
  --start-time "$FROM_MILLISECONDS" \
  --end-time "$TO_MILLISECONDS" \
  --query 'events[].{timestamp:timestamp,ingestionTime:ingestionTime,logStreamName:logStreamName,message:message}' \
  --output json \
  --no-cli-pager |
gzip > "$ARCHIVE_FILE"

OBJECT_KEY="${DESTINATION_PREFIX%/}/${TIMESTAMP}.json.gz"

AWS_PROFILE="$AWS_PROFILE" aws s3 cp \
  "$ARCHIVE_FILE" \
  "s3://${BUCKET}/${OBJECT_KEY}" \
  --region "$AWS_REGION" \
  --only-show-errors

echo "Log archive uploaded successfully:"
echo "s3://${BUCKET}/${OBJECT_KEY}"
