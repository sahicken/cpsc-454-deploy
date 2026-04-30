#!/usr/bin/env bash
set -euo pipefail

echo "Running CI checks..."

echo "1) Terraform fmt check"
cd terraform
if ! terraform fmt -check -diff >/dev/null 2>&1; then
  echo "terraform fmt needs changes" >&2
  terraform fmt -diff
  exit 1
fi

echo "2) Terraform validate"
# init with local backend for validate; providers will be downloaded but no state actions
terraform init -backend=false >/dev/null
terraform validate >/dev/null
cd ..

echo "3) Docker build (no push) - backend and frontend"
docker build -f docker/backend/Dockerfile -t ci-backend-test:latest docker || { echo "backend build failed"; exit 1; }
docker build -f docker/frontend/Dockerfile -t ci-frontend-test:latest docker || { echo "frontend build failed"; exit 1; }

echo "CI checks passed"
