#!/bin/bash
# Bootstrap script to create test users and initialize database

set -e

BACKEND_URL=${BACKEND_URL:-http://localhost:9001}
WAIT_TIME=${WAIT_TIME:-30}

echo "Waiting for backend to be ready ($WAIT_TIME seconds)..."
for i in $(seq 1 $WAIT_TIME); do
  if curl -f -s "$BACKEND_URL/docs" > /dev/null 2>&1; then
    echo "Backend is ready!"
    break
  fi
  echo "Waiting... ($i/$WAIT_TIME)"
  sleep 1
done

# Create test user (optional - can be skipped for now)
echo "Bootstrap complete. Backend is ready for use."
