#!/bin/bash

# Scrapper Playwright - Build and Push Script
# Usage: ./build-image.sh [build|push|build-push|login] [web|all]

set -e

# Resolve script directory to make paths robust when run from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Harbor Registry Configuration (default, can be overridden)
REGISTRY_DOMAIN_NAME="${REGISTRY_DOMAIN_NAME}"
ENVIRONMENT="smap"
WEB_SERVICE="playwright"

# Platform configuration for K8s compatibility
PLATFORM="linux/amd64"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Generate timestamp in format yyMMdd-HHmmss
generate_timestamp() {
    date +"%y%m%d-%H%M%S"
}

# Generate full image name with timestamp
generate_image_name() {
    local service="$1"
    local timestamp
    timestamp=$(generate_timestamp)
    echo "${REGISTRY_DOMAIN_NAME}/${ENVIRONMENT}/${service}:${timestamp}"
}

# Function to get Harbor credentials and registry domain
get_harbor_credentials() {
    # Prompt for registry domain if not set by env
    if [ -z "$REGISTRY_DOMAIN_NAME" ] || [ "$REGISTRY_DOMAIN_NAME" = "registry.tantai.dev" ]; then
        echo -n "Enter Harbor registry domain (default: registry.tantai.dev): "
        read input_registry
        if [ -n "$input_registry" ]; then
            REGISTRY_DOMAIN_NAME="$input_registry"
        fi
        export REGISTRY_DOMAIN_NAME
    fi

    # Check environment variables for username and password first
    if [ -n "$HARBOR_USERNAME" ] && [ -n "$HARBOR_PASSWORD" ]; then
        print_info "Using credentials from environment variables"
        return 0
    fi

    # Prompt for username if not set
    if [ -z "$HARBOR_USERNAME" ]; then
        echo -n "Enter Harbor username: "
        read HARBOR_USERNAME
        if [ -z "$HARBOR_USERNAME" ]; then
            print_error "Username cannot be empty"
            exit 1
        fi
        export HARBOR_USERNAME
    fi

    # Prompt for password if not set
    if [ -z "$HARBOR_PASSWORD" ]; then
        echo -n "Enter Harbor password: "
        read -s HARBOR_PASSWORD
        echo "" # New line after hidden input
        if [ -z "$HARBOR_PASSWORD" ]; then
            print_error "Password cannot be empty"
            exit 1
        fi
        export HARBOR_PASSWORD
    fi
}

# Function to login to Harbor registry
login_registry() {
    get_harbor_credentials

    print_info "Logging into Harbor registry: $REGISTRY_DOMAIN_NAME"
    echo "$HARBOR_PASSWORD" | docker login "$REGISTRY_DOMAIN_NAME" -u "$HARBOR_USERNAME" --password-stdin

    if [ $? -eq 0 ]; then
        print_success "Successfully logged into Harbor registry"
    else
        print_error "Failed to login to Harbor registry"
        exit 1
    fi
}

# Function to check if buildx is available
check_buildx() {
    if ! docker buildx version >/dev/null 2>&1; then
        print_error "Docker buildx is not available"
        print_info "Please enable Docker buildx or use Docker Desktop"
        exit 1
    fi

    # Create builder if not exists
    if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
        print_info "Creating multiarch builder..."
        docker buildx create --name multiarch-builder --use
    fi

    print_info "Using buildx builder: multiarch-builder"
    docker buildx use multiarch-builder
}

# Function to build Docker image for Playwright runner
build_image() {
    local service="$1"
    local dockerfile_path=""
    local service_name=""

    case "$service" in
        web)
            dockerfile_path="$SCRIPT_DIR/playwright.Dockerfile"
            service_name="$WEB_SERVICE"
            ;;
        *)
            print_error "Unknown service: $service (use 'web' or 'all')"
            exit 1
            ;;
    esac

    local image_name
    image_name=$(generate_image_name "$service_name")

    print_info "Building Docker image: $image_name"
    print_info "Service: $service_name"
    print_info "Dockerfile: $dockerfile_path"
    print_info "Build context: $SCRIPT_DIR"
    print_info "Platform: $PLATFORM"

    # Check if Dockerfile exists
    if [ ! -f "$dockerfile_path" ]; then
        print_error "Dockerfile not found: $dockerfile_path"
        exit 1
    fi

    # Check buildx availability
    check_buildx

    # Build image for specific platform
    docker buildx build \
        --platform "$PLATFORM" \
        --tag "$image_name" \
        --file "$dockerfile_path" \
        --load \
        "$SCRIPT_DIR"

    if [ $? -eq 0 ]; then
        print_success "Successfully built $service_name: $image_name"

        # Show image info
        print_info "Image details:"
        docker images | grep "$service_name" | head -3
    else
        print_error "Failed to build Docker image for $service_name"
        exit 1
    fi
}

# Function to build and push in one step (more efficient for cross-platform)
build_and_push_image() {
    local service="$1"
    local dockerfile_path=""
    local service_name=""

    case "$service" in
        web)
            dockerfile_path="$SCRIPT_DIR/playwright.Dockerfile"
            service_name="$WEB_SERVICE"
            ;;
        *)
            print_error "Unknown service: $service (use 'web' or 'all')"
            exit 1
            ;;
    esac

    local image_name
    image_name=$(generate_image_name "$service_name")

    print_info "Building and pushing Docker image: $image_name"
    print_info "Service: $service_name"
    print_info "Dockerfile: $dockerfile_path"
    print_info "Build context: $SCRIPT_DIR"
    print_info "Platform: $PLATFORM"

    # Check if Dockerfile exists
    if [ ! -f "$dockerfile_path" ]; then
        print_error "Dockerfile not found: $dockerfile_path"
        exit 1
    fi

    # Check buildx availability
    check_buildx

    # Build and push image for specific platform
    docker buildx build \
        --platform "$PLATFORM" \
        --tag "$image_name" \
        --file "$dockerfile_path" \
        --push \
        "$SCRIPT_DIR"

    if [ $? -eq 0 ]; then
        print_success "Successfully built and pushed $service_name: $image_name"
    else
        print_error "Failed to build and push Docker image for $service_name"
        exit 1
    fi
}

# Function to push Docker image
push_image() {
    local service="$1"
    local service_name=""

    case "$service" in
        web)
            service_name="$WEB_SERVICE"
            ;;
        *)
            print_error "Unknown service: $service (use 'web' or 'all')"
            exit 1
            ;;
    esac

    local latest_image
    latest_image=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep "$REGISTRY_DOMAIN_NAME/$ENVIRONMENT/$service_name" | head -1)

    if [ -z "$latest_image" ]; then
        print_error "No local image found for $service_name"
        print_info "Build an image first: $0 build $service"
        exit 1
    fi

    print_info "Found local image: $latest_image"
    print_info "Pushing $service_name to registry..."

    docker push "$latest_image"

    if [ $? -eq 0 ]; then
        print_success "Successfully pushed $service_name: $latest_image"
    else
        print_error "Failed to push Docker image for $service_name"
        print_info "Make sure you're logged in: $0 login"
        exit 1
    fi
}

# Function to build all services
build_all() {
    print_info "Building all services..."
    build_image "web"
    echo ""
    print_success "All services built successfully!"
}

# Function to push all services
push_all() {
    print_info "Pushing all services..."
    push_image "web"
    echo ""
    print_success "All services pushed successfully!"
}

# Function to build and push all services
build_and_push_all() {
    print_info "Building and pushing all services..."

    # Check if logged in
    if ! docker info 2>/dev/null | grep -q "Username: $HARBOR_USERNAME"; then
        print_warning "Not logged in to Harbor registry"
        login_registry
    fi

    build_and_push_image "web"
    echo ""
    print_success "All services built and pushed successfully!"
}

# Function to show help
show_help() {
    echo "Scrapper Playwright - Harbor Registry Build Script"
    echo ""
    echo "Registry Configuration:"
    echo "  Registry: $REGISTRY_DOMAIN_NAME"
    echo "  Project:  $ENVIRONMENT"
    echo "  Web:      $WEB_SERVICE"
    echo "  Platform: $PLATFORM"
    echo ""
    echo "Usage: $0 [command] [service]"
    echo ""
    echo "Commands:"
    echo "  build         - Build Playwright image with timestamp (for linux/amd64)"
    echo "  push          - Push latest Playwright image to Harbor registry"
    echo "  build-push    - Build and push Playwright image (recommended)"
    echo "  login         - Login to Harbor registry"
    echo "  platform      - Show current platform info"
    echo "  help          - Show this help message"
    echo ""
    echo "Services:"
    echo "  web           - Playwright image (this project)"
    echo "  all           - Same as 'web'"
    echo ""
    echo "Examples:"
    echo "  $0 login                 # Login to Harbor registry"
    echo "  $0 build web             # Build Playwright image"
    echo "  $0 build all             # Build (same as web)"
    echo "  $0 push web              # Push Playwright image"
    echo "  $0 build-push all        # Build and push Playwright image"
    echo ""
    echo "Image Format:"
    echo "  \$REGISTRY_DOMAIN_NAME/\$ENVIRONMENT/\$WEB_SERVICE:TIMESTAMP"
    echo "  Example: \$REGISTRY_DOMAIN_NAME/\$ENVIRONMENT/\$WEB_SERVICE:$(generate_timestamp)"
    echo ""
    echo "Notes:"
    echo "  - Images are built for linux/amd64 platform for K8s compatibility"
    echo "  - Use 'build-push' for better cross-platform support"
    echo "  - Requires Docker buildx (available in Docker Desktop)"
    echo ""
    echo "Credentials:"
    echo "  - Set REGISTRY_DOMAIN_NAME, HARBOR_USERNAME and HARBOR_PASSWORD env vars to use automatically"
    echo "  - Or script will prompt for registry domain and credentials when needed"
    echo "  - Example: export REGISTRY_DOMAIN_NAME=your.registry.com && export HARBOR_USERNAME=admin && export HARBOR_PASSWORD=secret"
}

# Function to show platform info
show_platform_info() {
    print_info "Current platform information:"
    echo "  Host platform: $(uname -m)"
    echo "  Docker version: $(docker --version)"
    echo "  Buildx available: $(docker buildx version >/dev/null 2>&1 && echo "Yes" || echo "No")"
    echo "  Target platform: $PLATFORM"
    echo ""

    print_info "Available builders:"
    docker buildx ls
}

# Parse arguments
COMMAND="${1:-help}"
SERVICE="${2:-all}"

# Main script logic
case "$COMMAND" in
    build)
        if [ "$SERVICE" = "all" ]; then
            build_all
        else
            build_image "$SERVICE"
        fi

        print_info "Next steps:"
        echo "  - Test the image locally"
        echo "  - Push to registry: $0 push $SERVICE"
        echo "  - Or build and push: $0 build-push $SERVICE"
        ;;
    push)
        if [ "$SERVICE" = "all" ]; then
            push_all
        else
            push_image "$SERVICE"
        fi
        ;;
    build-push)
        # Get credentials first (prompt if needed)
        get_harbor_credentials

        # Check if logged in
        if ! docker info 2>/dev/null | grep -q "Username:.*"; then
            print_warning "Not logged in to Harbor registry"
            login_registry
        fi

        if [ "$SERVICE" = "all" ]; then
            build_and_push_all
        else
            build_and_push_image "$SERVICE"
        fi

        print_success "Build and push completed successfully!"
        ;;
    login)
        login_registry
        ;;
    platform)
        show_platform_info
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        if [ -z "$1" ]; then
            # No arguments, show help
            show_help
        else
            print_error "Unknown command: $COMMAND"
            echo ""
            show_help
        fi
        exit 1
        ;;
esac

print_info "Done!"
