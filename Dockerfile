# ─────────────────────────────────────────────────────────────
# Multi-stage Dockerfile — optimised for size & free tier
# ─────────────────────────────────────────────────────────────

# Stage 1: Build dependencies
FROM python:3.11-slim AS builder

WORKDIR /build
COPY app/requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt


# Stage 2: Lean runtime image
FROM python:3.11-slim AS runtime

# Non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

WORKDIR /app

# Copy only installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY app/ .

# Switch to non-root
USER appuser

# Expose port
EXPOSE 8000

# Health-check so Docker itself knows if the container is healthy
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Start the server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
