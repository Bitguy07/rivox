# CPU Variant
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install python packages
COPY requirements.txt .
# For GPU variant, use: RUN pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu118
RUN pip install --no-cache-dir -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cpu

# Copy source code
COPY . .

# Expose port
EXPOSE 8000

# Start server
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
