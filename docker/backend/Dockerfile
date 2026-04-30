# Backend Dockerfile - FastAPI app with health endpoint and bootstrap

FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy backend code from submodule
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

EXPOSE 9001

# Use the health_wrapper.py from deployment repo to add /health endpoint
COPY deploy/health_wrapper.py /app/health_wrapper.py

CMD ["python3", "/app/health_wrapper.py"]
