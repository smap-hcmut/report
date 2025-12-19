# syntax=docker/dockerfile:1

# ==============================================================================
# STAGE 1: BUILDER (Use uv for ultra-fast builds)
# ==============================================================================
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Optimize for uv and build performance
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_CACHE_DIR=/tmp/uv-cache \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Install build dependencies in single layer with cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 1. Install dependencies first (better caching)
RUN --mount=type=cache,target=/tmp/uv-cache \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# 2. Copy only necessary source files (exclude tests, docs, etc.)
COPY app/ ./app/
COPY application/ ./application/
COPY config/ ./config/
COPY domain/ ./domain/
COPY internal/ ./internal/
COPY utils/ ./utils/
COPY pyproject.toml uv.lock ./

# 3. Install project (final sync)
RUN --mount=type=cache,target=/tmp/uv-cache \
    uv sync --frozen --no-dev --no-install-workspace

# ==============================================================================
# STAGE 2: RUNTIME (Optimized for YouTube scraping)
# ==============================================================================
FROM python:3.12-slim-bookworm AS runtime

# Standard OCI Metadata
LABEL org.opencontainers.image.title="SMAP YouTube Scraper Service" \
    org.opencontainers.image.description="Fast YouTube Scraper with yt-dlp and UV" \
    org.opencontainers.image.source="https://github.com/nguyentantai21042004/smap-ai-internal" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version="1.0.0"

# Optimized environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH="/app" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install minimal runtime dependencies in single layer
# yt-dlp may need curl for some extractors
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/* \
    && find /usr/share -type f -name "*.pyc" -delete \
    && find /usr/share -type d -name "__pycache__" -delete

# Copy virtual environment (optimized layer)
COPY --from=builder --chown=1000:1000 /app/.venv /app/.venv

# Copy source code in single layer
COPY --from=builder --chown=1000:1000 /app/app /app/app
COPY --from=builder --chown=1000:1000 /app/application /app/application
COPY --from=builder --chown=1000:1000 /app/config /app/config
COPY --from=builder --chown=1000:1000 /app/domain /app/domain
COPY --from=builder --chown=1000:1000 /app/internal /app/internal
COPY --from=builder --chown=1000:1000 /app/utils /app/utils

# Create non-root user with specific UID/GID for K8s compatibility
RUN groupadd -g 1000 appuser && \
    useradd -r -u 1000 -g appuser -d /app -s /sbin/nologin appuser && \
    mkdir -p /app/tmp /app/logs /app/downloads && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER 1000:1000

# Optimized health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=2 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

# Use exec form for better signal handling (using python directly, uv not needed in runtime)
CMD ["python", "-m", "app.worker_service"]
