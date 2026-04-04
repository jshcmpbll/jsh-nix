.PHONY: help setup dev-setup build run test fmt lint clean docker-up docker-down

help:
	@echo "Receipt API - Makefile Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup           - Initial setup (copy .env.example to .env)"
	@echo "  make dev-setup       - Setup for development (includes docker)"
	@echo ""
	@echo "Development:"
	@echo "  make run             - Run the application"
	@echo "  make build           - Build release binary"
	@echo "  make test            - Run tests"
	@echo "  make fmt             - Format code"
	@echo "  make lint            - Lint code with clippy"
	@echo "  make watch           - Run with cargo-watch (requires installation)"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-up       - Start PostgreSQL container"
	@echo "  make docker-down     - Stop PostgreSQL container"
	@echo "  make docker-clean    - Stop and remove PostgreSQL data"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean           - Remove build artifacts"

setup:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✓ Created .env file"; \
	else \
		echo "✓ .env file already exists"; \
	fi

dev-setup: setup
	@echo "Setting up development environment..."
	@command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting."; exit 1; }
	@echo "✓ Docker found"
	@echo "Starting PostgreSQL..."
	@docker-compose up -d
	@echo "✓ PostgreSQL is running"
	@echo "✓ Development environment ready!"
	@echo ""
	@echo "Run 'make run' to start the API server"

run: setup
	RUST_LOG=info cargo run

build:
	cargo build --release

test:
	cargo test

fmt:
	cargo fmt

lint:
	cargo clippy -- -D warnings

watch:
	@command -v cargo-watch >/dev/null 2>&1 || { echo "cargo-watch is not installed. Install with: cargo install cargo-watch"; exit 1; }
	cargo watch -x run

clean:
	cargo clean
	rm -rf target/

docker-up:
	docker-compose up -d
	@echo "✓ PostgreSQL is running on localhost:5432"

docker-down:
	docker-compose down

docker-clean:
	docker-compose down -v
	@echo "✓ PostgreSQL stopped and data removed"

.PHONY: build-nix
build-nix:
	nix build .#receipt-api
	@echo "✓ Built at ./result/bin/receipt-api"
