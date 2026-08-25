.PHONY: help docker-config docker-build docker-up docker-down docker-logs migrate-up migrate-down

help:
	@echo "Sadguru Catering OS"
	@echo ""
	@echo "Docker commands:"
	@echo "  make docker-config  Validate Docker Compose configuration"
	@echo "  make docker-build   Build application images"
	@echo "  make docker-up     Build and start the Docker stack"
	@echo "  make docker-down   Stop and remove the Docker stack"
	@echo "  make docker-logs   Follow Docker service logs"
	@echo ""
	@echo "Database commands:"
	@echo "  make migrate-up    Apply database migrations"
	@echo "  make migrate-down  Roll back the latest migration"

docker-config:
	docker compose config

docker-build:
	docker compose build

docker-up:
	docker compose up --build -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

migrate-up:
	docker compose exec backend /app/migrate up

migrate-down:
	docker compose exec backend /app/migrate down