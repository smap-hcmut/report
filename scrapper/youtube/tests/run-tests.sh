#!/bin/bash
# Automated test runner for YouTube scraper with FFmpeg integration
# Usage: ./run-tests.sh [unit|integration|all|cleanup]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored message
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Print section header
print_header() {
    echo ""
    print_msg "============================================" "$YELLOW"
    print_msg "$1" "$YELLOW"
    print_msg "============================================" "$YELLOW"
    echo ""
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_msg "Error: Docker is not running" "$RED"
        exit 1
    fi
}

# Run unit tests
run_unit_tests() {
    print_header "Running Unit Tests"
    docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit youtube-test-unit
    print_msg "✓ Unit tests completed" "$GREEN"
}

# Run integration tests
run_integration_tests() {
    print_header "Running Integration Tests"
    print_msg "Starting services (FFmpeg + MinIO)..." "$YELLOW"
    docker-compose -f docker-compose.test.yml up -d minio-test ffmpeg-service-test

    print_msg "Waiting for services to be healthy..." "$YELLOW"
    sleep 10

    print_msg "Running integration tests..." "$YELLOW"
    docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit youtube-test-integration
    print_msg "✓ Integration tests completed" "$GREEN"
}

# Run all tests
run_all_tests() {
    print_header "Running All Tests (Unit + Integration)"
    docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit youtube-test-all
    print_msg "✓ All tests completed" "$GREEN"
}

# Show coverage report
show_coverage() {
    print_header "Coverage Report"
    if [ -f "youtube/htmlcov/index.html" ]; then
        print_msg "Opening coverage report..." "$GREEN"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open youtube/htmlcov/index.html
        elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
            start youtube/htmlcov/index.html
        else
            xdg-open youtube/htmlcov/index.html 2>/dev/null || print_msg "Please open youtube/htmlcov/index.html manually" "$YELLOW"
        fi
    else
        print_msg "No coverage report found. Run tests with coverage first." "$RED"
    fi
}

# Cleanup
cleanup() {
    print_header "Cleaning Up"
    docker-compose -f docker-compose.test.yml down -v --remove-orphans
    print_msg "✓ Cleanup completed" "$GREEN"
}

# Show logs
show_logs() {
    print_header "Service Logs"
    docker-compose -f docker-compose.test.yml logs --tail=50 "$1"
}

# Main script
main() {
    check_docker

    case "${1:-all}" in
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        all)
            run_all_tests
            ;;
        coverage)
            show_coverage
            ;;
        cleanup)
            cleanup
            ;;
        logs)
            show_logs "$2"
            ;;
        help)
            print_header "YouTube Scraper Test Runner"
            echo "Usage: ./run-tests.sh [command]"
            echo ""
            echo "Commands:"
            echo "  unit          Run only unit tests"
            echo "  integration   Run only integration tests"
            echo "  all           Run all tests (default)"
            echo "  coverage      Open coverage report"
            echo "  cleanup       Stop services and remove volumes"
            echo "  logs [service] Show logs for a service"
            echo "  help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./run-tests.sh unit"
            echo "  ./run-tests.sh integration"
            echo "  ./run-tests.sh logs ffmpeg-service-test"
            echo "  ./run-tests.sh cleanup"
            ;;
        *)
            print_msg "Unknown command: $1" "$RED"
            print_msg "Use './run-tests.sh help' for usage information" "$YELLOW"
            exit 1
            ;;
    esac

    print_msg "" "$GREEN"
    print_msg "Done! 🎉" "$GREEN"
}

main "$@"
