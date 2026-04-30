#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID=${1:-${PROJECT_ID:-}}
if [ -z "$PROJECT_ID" ]; then
  echo "Usage: $0 <PROJECT_ID>" >&2
  exit 1
fi

cd "$(dirname "$0")/.."/terraform || exit 1
echo "Initializing terraform backend for project ${PROJECT_ID}..."
terraform init -backend-config="bucket=${PROJECT_ID}-terraform-state" -backend-config="prefix=deploy"

echo "Destroying staging resources (this will delete infra)..."
terraform destroy -var="gcp_project_id=${PROJECT_ID}" -auto-approve

echo "Done."
