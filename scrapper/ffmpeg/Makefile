.PHONY: help install run docker-build docker-up docker-down docker-logs clean test

# ==============================================================================
# HELPERS
# ==============================================================================
help:
	@echo "Available commands for FFmpeg Service:"
	@echo "  make install      - Install dependencies with uv"
	@echo "  make run          - Run API service"
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
	PYTHONPATH=. uv run uvicorn cmd.api.main:app --host 0.0.0.0 --port 8000 --reload

# Run without reload
run-prod:
	PYTHONPATH=. uv run uvicorn cmd.api.main:app --host 0.0.0.0 --port 8000

# ==============================================================================
# DOCKER OPERATIONS
# ==============================================================================
docker-build:
	docker build -f cmd/api/Dockerfile -t ffmpeg-service:latest .

docker-up:
	docker-compose up -d ffmpeg-service

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f ffmpeg-service

docker-restart:
	docker-compose restart ffmpeg-service

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
