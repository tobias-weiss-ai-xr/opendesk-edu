# SPDX-License-Identifier: Apache-2.0
# Semester Provisioning API Docker Image
# Docker-Image für die Semester-Provisioning-API

FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p logs

# Expose API port
EXPOSE 8000

# Run the API server
CMD ["uvicorn", "api.server:app", "--host", "0.0.0.0", "--port", "8000"]
