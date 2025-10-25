# XQuantify TradeStation - Management Makefile

.PHONY: help install uninstall build start stop restart status logs clean scale backup restore health monitor ssl-setup ssl-renew ssl-status fix-line-endings

# Default target
help:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║        XQuantify TradeStation Management Commands        ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Quick Start:"
	@echo "  install        - Interactive installation wizard (recommended)"
	@echo "  quick-start    - Fast install with defaults"
	@echo "  uninstall      - Remove XQuantify TradeStation (interactive)"
	@echo ""
	@echo "Container Management:"
	@echo "  build          - Build the TradeStation Docker image"
	@echo "  start          - Start TradeStation services"
	@echo "  stop           - Stop all TradeStation services"
	@echo "  restart        - Restart TradeStation services"
	@echo ""
	@echo "Monitoring & Logs:"
	@echo "  status         - Show status of all instances"
	@echo "  logs           - Show logs from main instance"
	@echo "  health         - Run health check"
	@echo "  monitor        - Start continuous monitoring"
	@echo ""
	@echo "Scaling:"
	@echo "  scale N=<num>  - Scale to N instances"
	@echo ""
	@echo "Maintenance:"
	@echo "  backup         - Create backup of all data"
	@echo "  restore        - Restore from latest backup"
	@echo "  clean          - Clean up containers and images"
	@echo "  update         - Update all containers"
	@echo ""
	@echo "SSL Management:"
	@echo "  ssl-setup      - Setup Let's Encrypt SSL certificate"
	@echo "  ssl-renew      - Manually renew SSL certificate"
	@echo "  ssl-status     - Check SSL certificate status"
	@echo "  ssl-self-signed - Generate self-signed SSL certificate"
	@echo ""
	@echo "Broker-Specific Builds:"
	@echo "  build-xm       - Build with XM Global MT5"
	@echo "  build-ic       - Build with IC Markets MT5"
	@echo "  build-fxpro    - Build with FxPro MT5"
	@echo ""
	@echo "Line Ending Management:"
	@echo "  fix-line-endings - Convert all files to LF (Unix) line endings"
	@echo ""
	@echo "Examples:"
	@echo "  make install              # Interactive setup"
	@echo "  make quick-start          # Fast default setup"
	@echo "  make build-xm && make start  # Start with XM broker"
	@echo "  make scale N=3            # Scale to 3 instances"
	@echo "  make logs                 # View logs"
	@echo ""

# Build the Docker image
build:
	@echo "Building XQuantify TradeStation image..."
	docker-compose build

# Start services
start:
	@echo "Starting XQuantify TradeStation services..."
	./scripts/scale.sh start

# Stop services
stop:
	@echo "Stopping XQuantify TradeStation services..."
	./scripts/scale.sh stop

# Restart services
restart: stop start

# Show status
status:
	@echo "Checking TradeStation instance status..."
	./scripts/scale.sh status

# Show logs
logs:
	@echo "Showing TradeStation logs..."
	./scripts/scale.sh logs mt5-main

# Clean up
clean:
	@echo "Cleaning up containers and images..."
	docker-compose down -v --remove-orphans
	docker system prune -f

# Scale instances
scale:
	@if [ -z "$(N)" ]; then \
		echo "Error: Please specify number of instances with N=<number>"; \
		echo "Example: make scale N=3"; \
		exit 1; \
	fi
	@echo "Scaling to $(N) instances..."
	./scripts/scale.sh scale $(N)

# Create backup
backup:
	@echo "Creating backup..."
	./scripts/backup.sh backup

# Restore from backup
restore:
	@echo "Available backups:"
	@./scripts/backup.sh list
	@echo ""
	@echo "To restore, run: ./scripts/backup.sh restore <backup_file>"

# Health check
health:
	@echo "Running health check..."
	./scripts/monitor.sh health

# Start monitoring
monitor:
	@echo "Starting monitoring..."
	./scripts/monitor.sh monitor

# Development helpers
dev-start:
	@echo "Starting development environment..."
	docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

dev-logs:
	@echo "Following development logs..."
	docker-compose -f docker-compose.yml -f docker-compose.override.yml logs -f

# Quick setup for new installations
setup:
	@echo "Setting up XQuantify TradeStation environment..."
	@if [ ! -f .env ]; then \
		echo "Creating .env file from template..."; \
		cp .env .env.backup; \
	fi
	@echo "Making scripts executable..."
	@chmod +x scripts/*.sh start.sh
	@echo "Creating required directories..."
	@mkdir -p data logs backups nginx/ssl
	@echo "Setup complete! Edit .env file and run 'make start'"

# Install system dependencies (Ubuntu/Debian)
install-deps:
	@echo "Installing Docker and Docker Compose..."
	@if ! command -v docker >/dev/null 2>&1; then \
		curl -fsSL https://get.docker.com -o get-docker.sh; \
		sudo sh get-docker.sh; \
		sudo usermod -aG docker $$USER; \
		rm get-docker.sh; \
	fi
	@if ! command -v docker-compose >/dev/null 2>&1; then \
		sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$$(uname -s)-$$(uname -m)" -o /usr/local/bin/docker-compose; \
		sudo chmod +x /usr/local/bin/docker-compose; \
	fi
	@echo "Dependencies installed. Please log out and back in to use Docker."

# Security setup
security-setup:
	@echo "Setting up security configurations..."
	@if [ ! -f nginx/ssl/cert.pem ]; then \
		echo "Generating self-signed SSL certificate..."; \
		mkdir -p nginx/ssl; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout nginx/ssl/key.pem \
			-out nginx/ssl/cert.pem \
			-subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"; \
	fi
	@echo "SSL certificate generated in nginx/ssl/"
	@echo "Update .env to enable SSL: SSL_ENABLED=true"

# Performance testing
perf-test:
	@echo "Running performance tests..."
	@for i in $$(seq 1 5); do \
		echo "Test $$i: Checking response time..."; \
		curl -w "@curl-format.txt" -o /dev/null -s http://localhost/health; \
	done

# Update all containers
update:
	@echo "Updating containers..."
	docker-compose pull
	docker-compose up -d
	@echo "Cleaning up old images..."
	docker image prune -f

# Interactive installation wizard
install:
	@echo "Starting XQuantify TradeStation installation wizard..."
	@chmod +x install.sh
	@./install.sh

# Uninstall XQuantify TradeStation
uninstall:
	@echo "Starting XQuantify TradeStation uninstall utility..."
	@chmod +x uninstall.sh
	@./uninstall.sh

# Quick start with defaults (non-interactive)
quick-start:
	@echo "Quick start installation with defaults..."
	@if [ ! -f .env ]; then \
		echo "Creating default .env file..."; \
		cp .env .env; \
	fi
	@chmod +x scripts/*.sh start.sh
	@mkdir -p data logs backups nginx/ssl
	@echo "Building with default MetaQuotes broker..."
	docker-compose build
	@echo "Starting services..."
	docker-compose up -d
	@echo "✓ Quick start complete!"
	@echo "Access MT5 at: http://localhost"

# Broker-specific build targets
build-xm:
	@echo "Building with XM Global broker..."
	docker-compose build --build-arg BROKER=xm

build-ic:
	@echo "Building with IC Markets broker..."
	docker-compose build --build-arg BROKER=ic_markets

build-fxpro:
	@echo "Building with FxPro broker..."
	docker-compose build --build-arg BROKER=fxpro

build-pepperstone:
	@echo "Building with Pepperstone broker..."
	docker-compose build --build-arg BROKER=pepperstone

build-roboforex:
	@echo "Building with RoboForex broker..."
	docker-compose build --build-arg BROKER=roboforex

build-exness:
	@echo "Building with Exness broker..."
	docker-compose build --build-arg BROKER=exness

build-bybit:
	@echo "Building with Bybit broker..."
	docker-compose build --build-arg BROKER=bybit

# Build with custom installer URL
build-custom:
	@if [ -z "$(URL)" ]; then \
		echo "Error: Please specify installer URL with URL=<url>"; \
		echo "Example: make build-custom URL=https://your-broker.com/mt5setup.exe"; \
		exit 1; \
	fi
	@echo "Building with custom installer: $(URL)"
	docker-compose build --build-arg MT5_INSTALLER_URL=$(URL)

# List available brokers
list-brokers:
	@echo "Available broker profiles:"
	@echo ""
	@cat brokers.json | jq -r '.brokers | to_entries[] | "  \(.key): \(.value.name)"'
	@echo ""
	@echo "To build with a specific broker:"
	@echo "  make build-<broker_key>"
	@echo "  Example: make build-xm"

# SSL Management Commands
ssl-setup:
	@echo "Setting up Let's Encrypt SSL certificate..."
	@chmod +x scripts/setup-letsencrypt.sh
	@./scripts/setup-letsencrypt.sh

ssl-renew:
	@echo "Renewing SSL certificate..."
	@chmod +x scripts/renew-ssl.sh
	@./scripts/renew-ssl.sh

ssl-status:
	@echo "Checking SSL certificate status..."
	@if [ -f nginx/certbot/conf/live/*/cert.pem ]; then \
		openssl x509 -in nginx/certbot/conf/live/*/cert.pem -noout -dates -subject; \
	elif [ -f nginx/ssl/cert.pem ]; then \
		openssl x509 -in nginx/ssl/cert.pem -noout -dates -subject; \
	else \
		echo "No SSL certificate found."; \
		echo "Run 'make ssl-setup' to create one."; \
	fi

ssl-self-signed:
	@echo "Generating self-signed SSL certificate..."
	@chmod +x scripts/generate-ssl.sh
	@./scripts/generate-ssl.sh

# Line Ending Management
fix-line-endings:
	@echo "Converting all files to LF (Unix) line endings..."
	@if [ "$$(uname -s)" = "Linux" ] || [ "$$(uname -s)" = "Darwin" ]; then \
		chmod +x scripts/fix-line-endings.sh; \
		./scripts/fix-line-endings.sh; \
	else \
		echo "Running PowerShell conversion script..."; \
		powershell -ExecutionPolicy Bypass -File scripts/fix-line-endings.ps1; \
	fi
	@echo "✓ Line endings fixed!"
	@echo ""
	@echo "Next steps to commit changes:"
	@echo "  1. git add --renormalize ."
	@echo "  2. git status"
	@echo "  3. git commit -m 'Fix line endings to LF'"