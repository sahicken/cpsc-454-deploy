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

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "9001"]
