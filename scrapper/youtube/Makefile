.PHONY: help install run docker-build docker-up docker-down docker-logs clean test

# ==============================================================================
# HELPERS
# ==============================================================================
help:
	@echo "Available commands for YouTube Scraper:"
	@echo "  make install      - Install dependencies with uv"
	@echo "  make run          - Run worker service"
	@echo "  make docker-build - Build Docker image"
	@echo "  make docker-up    - Start service with docker-compose"
	@echo "  make docker-down  - Stop service"
	@echo "  make docker-logs  - View service logs"
	@echo "  make clean        - Clean cache and build files"
	@echo "  make test         - Run tests"

# ==============================================================================
# DEPENDENCY MANAGEMENT (UV)
# ==============================================================================
install:
	uv sync

# Upgrade dependencies
upgrade:
	uv lock --upgrade

# Add new dependency
add:
	uv add $(pkg)

# ==============================================================================
# RUN SERVICES
# ==============================================================================
run:
	PYTHONPATH=. uv run app/main.py

# Run worker service
run-worker:
	PYTHONPATH=. uv run app/worker_service.py

# ==============================================================================
# DOCKER OPERATIONS
# ==============================================================================
docker-build:
	docker build -t youtube-scraper:latest .

docker-up:
	docker-compose up -d youtube-scraper

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f youtube-scraper

docker-restart:
	docker-compose restart youtube-scraper

# ==============================================================================
# CODE QUALITY & TESTING
# ==============================================================================
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	rm -rf .pytest_cache
	rm -rf htmlcov
	rm -rf .coverage
	uv clean

test:
	uv run pytest -v
