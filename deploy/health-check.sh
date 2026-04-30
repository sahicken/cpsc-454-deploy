#!/bin/bash
# Health check helper script

SERVICE_NAME=$1
SERVICE_PORT=$2
HEALTH_PATH=${3:-/health}

if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_PORT" ]; then
  echo "Usage: $0 <service-name> <port> [health-path]"
  exit 1
fi

echo "Health check for $SERVICE_NAME on port $SERVICE_PORT at path $HEALTH_PATH"

curl -f -s "http://localhost:$SERVICE_PORT$HEALTH_PATH" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "$SERVICE_NAME is healthy"
  exit 0
else
  echo "$SERVICE_NAME is unhealthy"
  exit 1
fi
