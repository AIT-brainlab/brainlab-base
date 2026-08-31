FROM python:3.12-slim

# Set timezone and proxy friendly settings
ENV TZ=Asia/Bangkok \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# Install system utilities and poppler for PDF/PostScript processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    poppler-utils \
    ghostscript \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY app/ /app/app/

EXPOSE 8080

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
