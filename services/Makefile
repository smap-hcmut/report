# Makefile for cleaning ignored files in services directory
# Use this after copying new source code to clean up files that should be ignored

.PHONY: help clean clean-python clean-go clean-typescript clean-all clean-ide clean-locks clean-logs clean-cache

help:
	@echo "Available commands:"
	@echo "  make clean-all          - Clean all ignored files (Python, Go, TypeScript, IDE, locks, logs, cache)"
	@echo "  make clean-python       - Clean Python-specific ignored files"
	@echo "  make clean-go           - Clean Go-specific ignored files"
	@echo "  make clean-typescript   - Clean TypeScript/Next.js-specific ignored files"
	@echo "  make clean-ide          - Clean IDE and editor files"
	@echo "  make clean-locks        - Clean lock files (uv.lock, go.sum, package-lock.json, etc.)"
	@echo "  make clean-logs         - Clean log files"
	@echo "  make clean-cache        - Clean cache and compiled files"
	@echo ""
	@echo "Examples:"
	@echo "  make clean-all          # Clean everything after copying new code"
	@echo "  make clean-python        # Clean only Python services"

# ============================================
# Clean All
# ============================================
clean-all: clean-python clean-go clean-typescript clean-ide clean-locks clean-logs clean-cache
	@echo "✓ All ignored files cleaned"

# ============================================
# Python Services Cleanup
# ============================================
clean-python:
	@echo "Cleaning Python services..."
	@find . -type d \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		\( -name ".venv" -o -name "venv" -o -name "ENV" -o -name "env" \) -exec rm -rf {} + 2>/dev/null || true
	@find . -type d \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		-name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		\( -name "*.pyc" -o -name "*.pyo" -o -name "*.py[cod]" \) -delete 2>/dev/null || true
	@find . -type d \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		-name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		-name "uv.lock" -delete 2>/dev/null || true
	@find . -type d \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		\( -name ".pytest_cache" -o -name ".mypy_cache" -o -name ".ruff_cache" \) -exec rm -rf {} + 2>/dev/null || true
	@find . -type f \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		-name ".coverage" -delete 2>/dev/null || true
	@find . -type d \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		-name "htmlcov" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		\( -name "build" -o -name "dist" \) -exec rm -rf {} + 2>/dev/null || true
	@find . -type f \( -path "*/speech2text/*" -o -path "*/analytic/*" -o -path "*/scrapper/*" \) \
		-name "*.so" -o -name "*.so.*" -delete 2>/dev/null || true
	@echo "✓ Python services cleaned"

# ============================================
# Go Services Cleanup
# ============================================
clean-go:
	@echo "Cleaning Go services..."
	@find . -type d \( -path "*/collector/*" -o -path "*/identity/*" -o -path "*/project/*" -o -path "*/websocket/*" \) \
		-name "vendor" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d \( -path "*/collector/*" -o -path "*/identity/*" -o -path "*/project/*" -o -path "*/websocket/*" \) \
		-name "bin" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f \( -path "*/collector/*" -o -path "*/identity/*" -o -path "*/project/*" -o -path "*/websocket/*" \) \
		-name "go.sum" -delete 2>/dev/null || true
	@find . -type f \( -path "*/collector/*" -o -path "*/identity/*" -o -path "*/project/*" -o -path "*/websocket/*" \) \
		\( -name "*.test" -o -name "*.out" \) -delete 2>/dev/null || true
	@find . -type d \( -path "*/collector/*" -o -path "*/identity/*" -o -path "*/project/*" -o -path "*/websocket/*" \) \
		-name "coverage" -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Go services cleaned"

# ============================================
# TypeScript/Next.js Services Cleanup
# ============================================
clean-typescript:
	@echo "Cleaning TypeScript/Next.js services..."
	@find . -type d -path "*/web-ui/*" -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -path "*/web-ui/*" -name ".next" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -path "*/web-ui/*" \( -name "out" -o -name "dist" -o -name "build" \) -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -path "*/web-ui/*" \
		\( -name "package-lock.json" -o -name "pnpm-lock.yaml" -o -name "yarn.lock" \) -delete 2>/dev/null || true
	@find . -type f -path "*/web-ui/*" \
		\( -name "*.tsbuildinfo" -o -name "next-env.d.ts" \) -delete 2>/dev/null || true
	@find . -type d -path "*/web-ui/*" \
		\( -name ".cache" -o -name ".parcel-cache" -o -name "coverage" -o -name "test-results" -o -name "playwright-report" \) \
		-exec rm -rf {} + 2>/dev/null || true
	@find . -type f -path "*/web-ui/*" \
		-name ".eslintcache" -o -name ".stylelintcache" -delete 2>/dev/null || true
	@echo "✓ TypeScript/Next.js services cleaned"

# ============================================
# IDE & Editor Files Cleanup
# ============================================
clean-ide:
	@echo "Cleaning IDE and editor files..."
	@find . -type d \
		\( -name ".vscode" -o -name ".idea" -o -name ".cursor" -o -name ".agent" -o -name ".claude" -o -name ".kiro" -o -name ".gemini" \) \
		-exec rm -rf {} + 2>/dev/null || true
	@find . -type f \
		\( -name "AGENTS.md" -o -name "CLAUDE.md" \) -not -path "*/openspec/*" -delete 2>/dev/null || true
	@find . -type f \
		\( -name "*.swp" -o -name "*.swo" -o -name "*~" \) -delete 2>/dev/null || true
	@find . -type f -name ".DS_Store" -delete 2>/dev/null || true
	@find . -type f -name "Thumbs.db" -delete 2>/dev/null || true
	@find . -type f -name ".env" -not -name ".env.example" -delete 2>/dev/null || true
	@echo "✓ IDE and editor files cleaned"

# ============================================
# Lock Files Cleanup
# ============================================
clean-locks:
	@echo "Cleaning lock files..."
	@find . -type f -name "uv.lock" -delete 2>/dev/null || true
	@find . -type f -name "go.sum" -delete 2>/dev/null || true
	@find . -type f \( -name "package-lock.json" -o -name "pnpm-lock.yaml" -o -name "yarn.lock" \) -delete 2>/dev/null || true
	@echo "✓ Lock files cleaned"

# ============================================
# Log Files Cleanup
# ============================================
clean-logs:
	@echo "Cleaning log files..."
	@find . -type d -name "logs" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.log" -delete 2>/dev/null || true
	@echo "✓ Log files cleaned"

# ============================================
# Cache & Compiled Files Cleanup
# ============================================
clean-cache:
	@echo "Cleaning cache and compiled files..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f \( -name "*.pyc" -o -name "*.pyo" \) -delete 2>/dev/null || true
	@find . -type d \( -name ".pytest_cache" -o -name ".mypy_cache" -o -name ".ruff_cache" \) -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".coverage" -delete 2>/dev/null || true
	@find . -type d -name "htmlcov" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "coverage" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tsbuildinfo" -delete 2>/dev/null || true
	@find . -type f -name "*.so" -delete 2>/dev/null || true
	@find . -type f -name "*.so.*" -delete 2>/dev/null || true
	@find . -type d \( -name ".cache" -o -name ".parcel-cache" \) -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".eslintcache" -o -name ".stylelintcache" -delete 2>/dev/null || true
	@echo "✓ Cache and compiled files cleaned"
