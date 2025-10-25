# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**XQuantify TradeStation** is a professional MetaTrader 5 Docker deployment platform that provides browser-based access to MT5 trading platform via noVNC. The enterprise-grade architecture consists of containerized MT5 instances running under Wine, with nginx load balancing, monitoring, and auto-scaling capabilities.

## Core Commands

### Installation and Setup
```bash
# Interactive installation wizard (recommended for first-time setup)
make install
./install.sh

# Quick start with defaults
make quick-start

# Uninstall (removes all containers, images, with optional data preservation)
make uninstall
./uninstall.sh

# Switch broker after installation
./scripts/switch-broker.sh
```

### SSL/HTTPS Setup
```bash
# Setup Let's Encrypt SSL (automatic, free SSL certificates)
make ssl-setup
./scripts/setup-letsencrypt.sh <your-domain.com>

# Generate self-signed SSL certificate (for testing/development)
make ssl-self-signed
./scripts/generate-ssl.sh

# Check SSL certificate status
make ssl-status

# Manually renew SSL certificate
make ssl-renew
./scripts/renew-ssl.sh
```

### Primary Development Commands
```bash
# Build the MT5 Docker image
make build

# Build with specific broker
make build-xm          # XM Global
make build-ic          # IC Markets
make build-fxpro       # FxPro
make build-custom URL=<installer_url>  # Custom broker

# Start services (main instance + nginx + watchtower)
make start
./scripts/scale.sh start

# Check status and health
make status
make health
./scripts/monitor.sh health

# View logs
make logs
./scripts/scale.sh logs mt5-main

# Stop all services
make stop
./scripts/scale.sh stop
```

### Scaling Operations
```bash
# Scale to specific number of instances
make scale N=3
./scripts/scale.sh scale 3

# Create named instance
./scripts/scale.sh create mt5-client1

# Remove specific instance
./scripts/scale.sh remove mt5-client1
```

### Monitoring and Maintenance
```bash
# Continuous monitoring
./scripts/monitor.sh monitor

# View detailed metrics
./scripts/monitor.sh metrics

# Create backup
make backup
./scripts/backup.sh backup

# Restore from backup
./scripts/backup.sh restore <backup_file>
```

### Development Environment
```bash
# Start with development overrides (includes Portainer)
make dev-start

# Follow development logs
make dev-logs

# Initial setup for new installations
make setup
```

## Architecture Overview

### Multi-Container System
- **mt5-instance**: Core MT5 container with Wine, X11, VNC, and noVNC
- **nginx**: Load balancer distributing traffic across MT5 instances with SSL/TLS support
- **certbot**: Automatic SSL certificate management and renewal (Let's Encrypt)
- **watchtower**: Automatic container updates
- **portainer**: Container management UI (dev environment)

### Service Communication
- External traffic → nginx (port 80/443) → MT5 instances (port 6080)
- Direct VNC access available on port 5901
- All containers communicate via `mt5-network` bridge network

### Data Flow
1. Browser connects to nginx load balancer
2. Nginx forwards to available MT5 instance
3. noVNC serves web-based VNC client
4. X11vnc captures Wine/MT5 desktop
5. Xvfb provides virtual display for Wine

### Directory Structure
- `data/`: Persistent MT5 data (mounted per instance)
- `logs/`: Application and container logs
- `configs/`: Wine and application configurations
- `scripts/`: Management automation scripts
- `nginx/`: Load balancer configuration and SSL certificates

## Key Configuration Files

### Environment Variables (.env)
Critical settings for MT5 credentials, scaling limits, monitoring, and security. The file contains:
- VNC_PASSWORD: Access password for VNC sessions
- MT5_LOGIN/PASSWORD/SERVER: Auto-login credentials
- MAX_INSTANCES: Scaling upper limit (default: 10)
- ALERT_EMAIL/WEBHOOK_URL: Monitoring notifications

### Docker Compose
- `docker-compose.yml`: Production services definition
- `docker-compose.override.yml`: Development additions (Portainer, debug settings)

### Process Management
- `supervisord.conf`: Manages Xvfb, fluxbox, x11vnc, noVNC, and MT5 installer
- `start.sh`: Container entrypoint handling VNC password and directory setup

## Scaling Architecture

### Instance Management
The scaling system supports dynamic instance creation with automatic port allocation:
- Base ports: 6080 (noVNC), 5901 (VNC)
- Auto-incremented for additional instances
- Each instance gets isolated data/logs directories
- Nginx upstream configuration updates automatically

### Resource Isolation
- Memory limits: 2GB per instance (configurable)
- CPU limits: 2 cores per instance
- Network isolation via Docker bridge
- Volume separation for data persistence

## Monitoring System

### Health Checks
- Container-level: Docker health checks via curl to noVNC
- Application-level: Process monitoring via supervisord
- Resource monitoring: CPU/memory usage tracking
- Network connectivity: Port availability checks

### Alert Integration
- Email notifications via mail command
- Webhook integration (Slack/Discord compatible)
- Log aggregation in `logs/monitor.log`
- Threshold-based alerting (CPU >80%, Memory >80%)

## Security Considerations

### Network Security
- IP-based access control via ALLOWED_IPS environment variable
- SSL certificate generation and management (Let's Encrypt or self-signed)
- Automatic SSL certificate renewal via certbot container
- Firewall configuration recommendations in README

### SSL/HTTPS Configuration
The platform supports two SSL certificate options:

1. **Let's Encrypt (Recommended for Production)**
   - Free, trusted SSL certificates
   - Automatic renewal every 12 hours via certbot container
   - Requires a valid domain name pointing to your server
   - Port 80 must be accessible for ACME challenge
   - Setup during installation or run `make ssl-setup`
   - Certificates stored in `nginx/certbot/conf/`
   - Automatic cron job for weekly renewal checks

2. **Self-Signed Certificates (Development/Testing)**
   - Quick setup without domain requirements
   - Browser security warnings (expected behavior)
   - Generated via `make ssl-self-signed`
   - 365-day validity by default
   - Certificates stored in `nginx/ssl/`

SSL configuration in .env:
- SSL_ENABLED: true/false
- SSL_DOMAIN: Your domain name (for Let's Encrypt)
- SSL_EMAIL: Email for certificate notifications
- SSL_CERT_PATH: Path to certificate file
- SSL_KEY_PATH: Path to private key file

### Container Security
- Non-root user execution (mt5user)
- Read-only configuration mounts
- Resource limits to prevent DoS
- Isolated networks per deployment
- Automatic SSL certificate updates without service interruption

## Common Troubleshooting

### Container Issues
- Check logs: `docker-compose logs mt5-instance`
- Resource check: `docker system df` and `free -h`
- Network connectivity: `netstat -tuln | grep 5901`

### Wine/Display Issues
- Reset Wine prefix: `docker-compose exec mt5-instance wine wineboot --init`
- Restart X services: `docker-compose restart mt5-instance`
- Check display: Verify DISPLAY=:1 environment variable

### Performance Optimization
- Adjust memory limits in docker-compose.yml
- Modify Wine video memory in configs/wine.conf
- Use SSD storage for data volumes
- Monitor resource usage with `./scripts/monitor.sh metrics`

## Integration Points

### External Systems
- Nginx upstream configuration for load balancing
- Watchtower for automatic updates
- External monitoring systems via webhook alerts
- Backup storage integration via mounted volumes

### Development Extensions
- Additional MT5 instances via scaling scripts
- Custom Wine configurations in configs/
- Extended monitoring via additional supervisord programs
- SSL certificate automation via Let's Encrypt integration