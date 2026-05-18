# ============================================================
# Task 4b: Backend — Python Flask REST API
# ============================================================

# Use a slim Python base image
FROM python:3.11-slim

LABEL description="Lab2 Backend - Flask REST API"

WORKDIR /app

# Install dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
