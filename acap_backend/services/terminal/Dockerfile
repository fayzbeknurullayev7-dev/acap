FROM python:3.12-slim

# Install bash + common dev tools for the terminal
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl git vim nano wget unzip \
    nodejs npm \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m -s /bin/bash acap_user
USER acap_user

EXPOSE 8003
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8003"]
