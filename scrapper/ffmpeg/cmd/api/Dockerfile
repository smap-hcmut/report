# syntax=docker/dockerfile:1

# ==============================================================================
# STAGE 1: BUILDER (Use uv for ultra-fast builds)
# ==============================================================================
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Optimize for uv
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install build dependencies (needed for compiling packages)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# 1. Install dependencies (This layer changes infrequently, can be cached)
# Use bind mount to avoid copying files into the image, keep layers clean
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# 2. Copy source code and install project
COPY . .

# 3. Final sync to install actual source code into venv
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# ==============================================================================
# STAGE 2: RUNTIME (Python Slim with FFmpeg)
# ==============================================================================
FROM python:3.12-slim AS runtime

# Standard OCI Metadata
LABEL org.opencontainers.image.title="SMAP FFmpeg Conversion Service" \
      org.opencontainers.image.description="Fast FFmpeg API with MinIO and UV" \
      org.opencontainers.image.source="https://github.com/nguyentantai21042004/smap-ai-internal" \
      org.opencontainers.image.licenses="MIT"

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH="/app" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install runtime dependencies (FFmpeg + minimal packages)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    ffmpeg \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/*

# Copy virtual environment from Builder
COPY --from=builder /app/.venv /app/.venv

# Copy source code (all required modules)
COPY --from=builder /app/core /app/core
COPY --from=builder /app/services /app/services
COPY --from=builder /app/models /app/models
COPY --from=builder /app/domain /app/domain
COPY --from=builder /app/cmd /app/cmd
COPY --from=builder /app/__init__.py /app/__init__.py

# Create non-root user for security
RUN groupadd -r appuser && \
    useradd -r -g appuser -d /app -s /sbin/nologin appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check for FastAPI service
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run API service
CMD ["uvicorn", "cmd.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
