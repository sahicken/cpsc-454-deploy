#!/usr/bin/env python3
"""
Health endpoint wrapper for FastAPI backend.
This injects a /health endpoint into the existing server.py app.
"""

import sys
import os

# Add backend submodule to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

# Import the original app
from server import app

# Add health endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint for load balancer."""
    return {
        "status": "healthy",
        "service": "backend"
    }

if __name__ == "__main__":
    import uvicorn
    
    # Load env vars from .env.local if present
    if os.path.exists(".env.local"):
        from dotenv import load_dotenv
        load_dotenv(".env.local")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=int(os.getenv("PORT", 9001)),
        log_level="info"
    )
