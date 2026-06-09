# filename: acap_backend/services/files/Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Non-root user; /workspaces volume egaligi shu user'da bo'lsin
RUN useradd --create-home --uid 1000 appuser \
    && mkdir -p /workspaces \
    && chown -R appuser:appuser /workspaces /app
USER appuser

EXPOSE 8004

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8004"]
