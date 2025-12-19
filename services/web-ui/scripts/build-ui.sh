#!/bin/bash

# SMAP Web UI - Build and Push Script
# Usage: ./build-ui.sh [build-push|login|help]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REGISTRY="${REGISTRY:-registry.tantai.dev}"
PROJECT="smap"
SERVICE="smap-web"
DOCKERFILE="Dockerfile"
PLATFORM="linux/amd64"

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Generate image tag with timestamp
generate_tag() {
    date +"%y%m%d-%H%M%S"
}

# Get full image name
get_image_name() {
    local tag="${1:-$(generate_tag)}"
    echo "${REGISTRY}/${PROJECT}/${SERVICE}:${tag}"
}

# Login to registry
login() {
    info "Logging into registry: $REGISTRY"
    
    # Use env vars if available
    if [ -n "$HARBOR_USERNAME" ] && [ -n "$HARBOR_PASSWORD" ]; then
        echo "$HARBOR_PASSWORD" | docker login "$REGISTRY" -u "$HARBOR_USERNAME" --password-stdin
    else
        # Prompt for credentials
        read -p "Username: " username
        read -sp "Password: " password
        echo ""
        echo "$password" | docker login "$REGISTRY" -u "$username" --password-stdin
    fi
    
    if [ $? -eq 0 ]; then
        success "Logged in successfully"
    else
        error "Login failed"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        exit 1
    fi
    
    # Check buildx
    if ! docker buildx version &> /dev/null; then
        error "Docker buildx is not available"
        exit 1
    fi
    
    # Check Dockerfile
    if [ ! -f "$DOCKERFILE" ]; then
        error "Dockerfile not found: $DOCKERFILE"
        exit 1
    fi
    
    # Check package.json
    if [ ! -f "package.json" ]; then
        error "package.json not found - not a Next.js project?"
        exit 1
    fi
}

# Build and push image
build_and_push() {
    check_prerequisites
    
    # Check if logged in
    if ! docker info 2>/dev/null | grep -q "Username:"; then
        warning "Not logged in, attempting to login..."
        login
    fi
    
    local tag=$(generate_tag)
    local image_name=$(get_image_name "$tag")
    local latest_name=$(get_image_name latest)
    
    info "Registry: $REGISTRY"
    info "Building image: $image_name"
    info "Platform: $PLATFORM"
    info "Dockerfile: $DOCKERFILE"
    echo ""
    
    # Get build args from environment or use defaults
    NEXT_PUBLIC_HOSTNAME="${NEXT_PUBLIC_HOSTNAME:-https://smap-api.tantai.dev}"
    NEXT_PUBLIC_WS_URL="${NEXT_PUBLIC_WS_URL:-wss://smap-api.tantai.dev/ws}"
    
    info "Build arguments:"
    echo "  NEXT_PUBLIC_HOSTNAME: $NEXT_PUBLIC_HOSTNAME"
    echo "  NEXT_PUBLIC_WS_URL: $NEXT_PUBLIC_WS_URL"
    echo ""
    
    # Build and push with attestation disabled for registry compatibility
    info "Starting multi-stage build..."
    docker buildx build \
        --platform "$PLATFORM" \
        --provenance=false \
        --sbom=false \
        --build-arg NEXT_PUBLIC_HOSTNAME="$NEXT_PUBLIC_HOSTNAME" \
        --build-arg NEXT_PUBLIC_WS_URL="$NEXT_PUBLIC_WS_URL" \
        --tag "$image_name" \
        --tag "$latest_name" \
        --file "$DOCKERFILE" \
        --push \
        --progress=plain \
        .
    
    if [ $? -eq 0 ]; then
        echo ""
        success "Image built and pushed successfully!"
        echo ""
        info "Tagged images:"
        echo "  - $image_name"
        echo "  - $latest_name"
        echo ""
        info "To deploy, update k8s/deployment.yaml with:"
        echo "  image: $image_name"
        echo ""
        info "Then apply:"
        echo "  kubectl apply -f k8s/"
    else
        error "Build and push failed"
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOF
${GREEN}SMAP Web UI - Build and Push Script${NC}

Usage: $0 [command]

Commands:
    build-push    Build and push Docker image (default)
    login         Login to registry
    help          Show this help

Examples:
    $0                    # Build and push
    $0 build-push         # Build and push
    $0 login              # Login to registry

Configuration:
    Registry:   $REGISTRY
    Project:    $PROJECT
    Service:    $SERVICE
    Platform:   $PLATFORM
    Dockerfile: $DOCKERFILE

Image Format:
    ${REGISTRY}/${PROJECT}/${SERVICE}:YYMMDD-HHMMSS
    ${REGISTRY}/${PROJECT}/${SERVICE}:latest

Environment Variables:
    REGISTRY                Docker registry URL (default: registry.tantai.dev)
    HARBOR_USERNAME         Registry username (optional)
    HARBOR_PASSWORD         Registry password (optional)
    PLATFORM                Build platform (default: linux/amd64)
    NEXT_PUBLIC_HOSTNAME    API base URL (default: https://smap-api.tantai.dev)
    NEXT_PUBLIC_WS_URL      WebSocket URL (default: wss://smap-api.tantai.dev/ws)

Build Process:
    1. Dependencies stage - Install npm packages
    2. Builder stage - Build Next.js app (standalone output)
    3. Runner stage - Minimal production image with Node.js

Features:
    - Multi-stage build for minimal image size
    - Standalone Next.js output
    - Non-root user for security
    - Health checks included
    - Optimized layer caching

Note:
    This builds the SMAP Web UI (Next.js frontend).
    After building, update k8s/deployment.yaml with the new image tag.

EOF
}

# Main
case "${1:-build-push}" in
    build-push)
        build_and_push
        ;;
    login)
        login
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
