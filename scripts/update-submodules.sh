#!/usr/bin/env bash
set -euo pipefail

echo "Updating submodules..."
git submodule update --init --remote --recursive
git add frontend backend || true
if git diff --cached --quiet; then
  echo "No submodule updates"
  exit 0
fi
git commit -m "chore: update submodules to latest"
echo "Created commit with submodule updates. Push manually or configure CI to push/PR."
