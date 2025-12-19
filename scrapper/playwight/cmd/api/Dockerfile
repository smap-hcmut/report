# Stage 1: Builder
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# Install build dependencies
# Using default Debian Node.js/npm to avoid external repo DNS issues
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# Install Playwright Browsers (Chromium only)
RUN /build/.venv/bin/playwright install chromium \
    && find "${PLAYWRIGHT_BROWSERS_PATH}" -path '*/locales/*' ! -name 'en-US.pak' -delete \
    && find "${PLAYWRIGHT_BROWSERS_PATH}" -name '*.dSYM' -prune -exec rm -rf {} +

# Install Node.js dependencies (Playwright Core)
RUN npm install --no-save playwright-core@1.55.0 \
    && npm cache clean --force

# Copy source code and install project
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Stage 2: Runtime
FROM python:3.12-slim-bookworm

# Standard OCI Metadata
LABEL org.opencontainers.image.title="SMAP Playwright Service" \
    org.opencontainers.image.description="Browser automation service with Playwright and UV" \
    org.opencontainers.image.source="https://github.com/nguyentantai21042004/smap-ai-internal" \
    org.opencontainers.image.licenses="MIT"

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH"

# Install runtime system dependencies
# Only nodejs is needed for runtime (no npm)
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    curl \
    xvfb \
    xauth \
    x11-utils \
    dbus \
    dbus-x11 \
    locales \
    tzdata \
    # Playwright system dependencies
    libatk-bridge2.0-0 libatk1.0-0 libcups2 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 libxfixes3 libpango-1.0-0 \
    libpangocairo-1.0-0 libasound2 libatspi2.0-0 libdbus-1-3 libx11-6 libx11-xcb1 \
    libxcb1 libxext6 ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/*

# Locale & timezone giống máy thật
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

WORKDIR /srv/playwright_api

# Copy artifacts from builder
COPY --from=builder /build/.venv /app/.venv
COPY --from=builder /ms-playwright /ms-playwright
COPY --from=builder /build ./

# Create directories with proper permissions for Playwright
RUN mkdir -p /run/dbus /tmp/.X11-unix /srv/playwright_api/tmp && \
    chmod 1777 /tmp/.X11-unix && \
    chmod 755 /run/dbus

# Create non-root user for security (Playwright needs special handling)
RUN groupadd -r appuser && \
    useradd -r -g appuser -d /srv/playwright_api -s /sbin/nologin appuser && \
    chown -R appuser:appuser /srv/playwright_api /ms-playwright /app && \
    chown -R appuser:appuser /run/dbus /tmp/.X11-unix /srv/playwright_api/tmp

# Switch to non-root user
USER appuser

EXPOSE 4444 8001

# Health check for FastAPI service
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

CMD ["bash", "scripts/start.sh"]