.PHONY: help backend-install backend-migrate backend-run backend-test backend-lint backend-format backend-shell backend-clean flutter-install flutter-run flutter-test flutter-clean docker-up docker-down docker-clean pre-commit-install pre-commit-run clean

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Paths
BACKEND_DIR := hoang_lam_backend
FLUTTER_DIR := hoang_lam_app
VENV_DIR := $(CURDIR)/.venv
PYTHON := $(VENV_DIR)/bin/python
PIP := $(VENV_DIR)/bin/pip
PRE_COMMIT := $(VENV_DIR)/bin/pre-commit

# Django settings
DJANGO_SETTINGS := backend.settings.development

help: ## Show this help message
	@echo "$(BLUE)Hoang Lam Heritage Management - Makefile Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-30s$(NC) %s\n", $$1, $$2}'

# ================================
# Backend (Django) Commands
# ================================

backend-install: ## Install Python dependencies
	@echo "$(BLUE)Installing backend dependencies...$(NC)"
	cd $(BACKEND_DIR) && $(PIP) install -r requirements.txt -r requirements-dev.txt

backend-migrate: ## Run Django migrations
	@echo "$(BLUE)Running migrations...$(NC)"
	cd $(BACKEND_DIR) && DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS) $(PYTHON) manage.py migrate

backend-makemigrations: ## Create new Django migrations
	@echo "$(BLUE)Creating migrations...$(NC)"
	cd $(BACKEND_DIR) && DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS) $(PYTHON) manage.py makemigrations

backend-run: ## Run Django development server
	@echo "$(BLUE)Starting Django server...$(NC)"
	cd $(BACKEND_DIR) && DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS) $(PYTHON) manage.py runserver

backend-test: ## Run backend tests
	@echo "$(BLUE)Running backend tests...$(NC)"
	cd $(BACKEND_DIR) && DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS) $(PYTHON) -m pytest

backend-test-coverage: ## Run backend tests with coverage report
	@echo "$(BLUE)Running backend tests with coverage...$(NC)"
	cd $(BACKEND_DIR) && DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS) $(PYTHON) -m pytest --cov --cov-report=html --cov-report=term

backend-lint: ## Run linting checks (flake8, isort, black)
	@echo "$(BLUE)Running linting checks...$(NC)"
	cd $(BACKEND_DIR) && $(PYTHON) -m flake8 .
	cd $(BACKEND_DIR) && $(PYTHON) -m isort --check-only .
	cd $(BACKEND_DIR) && $(PYTHON) -m black --check .

backend-format: ## Auto-format code with black and isort
	@echo "$(BLUE)Formatting backend code...$(NC)"
	cd $(BACKEND_DIR) && $(PYTHON) -m isort .
	cd $(BACKEND_DIR) && $(PYTHON) -m black .

backend-shell: ## Open Django shell
	@echo "$(BLUE)Opening Django shell...$(NC)"
	cd $(BACKEND_DIR) && DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS) $(PYTHON) manage.py shell

backend-createsuperuser: ## Create Django superuser
	@echo "$(BLUE)Creating superuser...$(NC)"
	cd $(BACKEND_DIR) && DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS) $(PYTHON) manage.py createsuperuser

backend-clean: ## Clean Python cache files
	@echo "$(BLUE)Cleaning backend cache...$(NC)"
	find $(BACKEND_DIR) -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find $(BACKEND_DIR) -type f -name "*.pyc" -delete
	find $(BACKEND_DIR) -type f -name "*.pyo" -delete
	rm -rf $(BACKEND_DIR)/htmlcov
	rm -rf $(BACKEND_DIR)/.pytest_cache
	rm -rf $(BACKEND_DIR)/.coverage

# ================================
# Flutter Commands
# ================================

flutter-install: ## Install Flutter dependencies
	@echo "$(BLUE)Installing Flutter dependencies...$(NC)"
	cd $(FLUTTER_DIR) && flutter pub get

flutter-run: ## Run Flutter app
	@echo "$(BLUE)Running Flutter app...$(NC)"
	cd $(FLUTTER_DIR) && flutter run

flutter-build: ## Build Flutter APK
	@echo "$(BLUE)Building Flutter APK...$(NC)"
	cd $(FLUTTER_DIR) && flutter build apk

flutter-test: ## Run Flutter tests
	@echo "$(BLUE)Running Flutter tests...$(NC)"
	cd $(FLUTTER_DIR) && flutter test

flutter-analyze: ## Analyze Flutter code
	@echo "$(BLUE)Analyzing Flutter code...$(NC)"
	cd $(FLUTTER_DIR) && flutter analyze

flutter-format: ## Format Flutter code
	@echo "$(BLUE)Formatting Flutter code...$(NC)"
	cd $(FLUTTER_DIR) && dart format .

flutter-clean: ## Clean Flutter build
	@echo "$(BLUE)Cleaning Flutter build...$(NC)"
	cd $(FLUTTER_DIR) && flutter clean
	cd $(FLUTTER_DIR) && rm -rf .dart_tool

# ================================
# Docker Commands
# ================================

docker-up: ## Start Docker containers
	@echo "$(BLUE)Starting Docker containers...$(NC)"
	docker-compose up -d

docker-down: ## Stop Docker containers
	@echo "$(BLUE)Stopping Docker containers...$(NC)"
	docker-compose down

docker-logs: ## View Docker logs
	@echo "$(BLUE)Viewing Docker logs...$(NC)"
	docker-compose logs -f

docker-clean: ## Remove Docker containers and volumes
	@echo "$(BLUE)Cleaning Docker...$(NC)"
	docker-compose down -v
	docker system prune -f

# ================================
# Pre-commit & Linting
# ================================

pre-commit-install: ## Install pre-commit hooks
	@echo "$(BLUE)Installing pre-commit hooks...$(NC)"
	$(PRE_COMMIT) install

pre-commit-run: ## Run pre-commit on all files
	@echo "$(BLUE)Running pre-commit checks...$(NC)"
	$(PRE_COMMIT) run --all-files

# ================================
# Combined Commands
# ================================

install: backend-install flutter-install pre-commit-install ## Install all dependencies
	@echo "$(GREEN)All dependencies installed!$(NC)"

test: backend-test flutter-test ## Run all tests
	@echo "$(GREEN)All tests completed!$(NC)"

lint: backend-lint flutter-analyze ## Run all linting checks
	@echo "$(GREEN)All linting checks completed!$(NC)"

format: backend-format flutter-format ## Format all code
	@echo "$(GREEN)All code formatted!$(NC)"

clean: backend-clean flutter-clean ## Clean all cache and build files
	@echo "$(GREEN)All cache cleaned!$(NC)"

dev-setup: install backend-migrate ## Complete development setup
	@echo "$(GREEN)Development environment ready!$(NC)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Copy $(BACKEND_DIR)/.env.example to $(BACKEND_DIR)/.env and configure"
	@echo "  2. Run: make backend-createsuperuser"
	@echo "  3. Run: make backend-run (in one terminal)"
	@echo "  4. Run: make flutter-run (in another terminal)"
