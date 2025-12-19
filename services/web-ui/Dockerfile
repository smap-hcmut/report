# ============================================
# Multi-stage Docker Build for Next.js
# ============================================

# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Install libc6-compat for better compatibility
RUN apk add --no-cache libc6-compat

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies with clean cache
RUN npm ci --legacy-peer-deps --omit=dev && \
    npm cache clean --force

# ============================================
# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

# Build arguments for NEXT_PUBLIC_* variables
ARG NEXT_PUBLIC_HOSTNAME
ARG NEXT_PUBLIC_WS_URL

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy only necessary source files
COPY package.json package-lock.json* ./
COPY next.config.ts tsconfig.json ./
COPY next-i18next.config.js ./
COPY postcss.config.mjs tailwind.config.js ./
COPY public ./public
COPY pages ./pages
COPY components ./components
COPY styles ./styles
COPY lib ./lib
COPY hooks ./hooks
COPY contexts ./contexts
COPY services ./services
COPY config ./config

# Set environment variables for build
ENV NEXT_TELEMETRY_DISABLED=1 \
    NODE_ENV=production \
    NEXT_PUBLIC_HOSTNAME=${NEXT_PUBLIC_HOSTNAME} \
    NEXT_PUBLIC_WS_URL=${NEXT_PUBLIC_WS_URL}

# Build the application
RUN npm run build

# ============================================
# Stage 3: Runner (Production)
FROM node:20-alpine AS runner
WORKDIR /app

# Set to production environment
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=5000 \
    HOSTNAME="0.0.0.0"

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy necessary files from builder
# Note: standalone mode includes public folder in .next/standalone
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:5000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Start the application with dumb-init
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "server.js"]
