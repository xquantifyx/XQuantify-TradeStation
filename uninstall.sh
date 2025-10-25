#!/bin/bash

# XQuantify TradeStation - Uninstall Script
# Complete removal of XQuantify TradeStation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${RED}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║       XQuantify TradeStation Uninstall Utility           ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_section() {
    echo -e "${MAGENTA}▶ $1${NC}"
}

# Confirmation
echo ""
print_warning "This will remove XQuantify TradeStation from your system."
echo ""
print_info "The following will be removed:"
echo "  • All running containers"
echo "  • Docker images"
echo "  • Docker networks"
echo "  • Docker volumes"
echo ""
print_info "You can choose to keep or remove:"
echo "  • MT5 data files"
echo "  • Log files"
echo "  • Backups"
echo "  • Configuration files"
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    print_info "Uninstall cancelled."
    exit 0
fi

# Ask about data preservation
echo ""
print_section "Data Preservation Options"
echo ""
read -p "Keep MT5 data files? (y/n) [y]: " keep_data
keep_data=${keep_data:-y}

read -p "Keep log files? (y/n) [n]: " keep_logs
keep_logs=${keep_logs:-n}

read -p "Keep backups? (y/n) [y]: " keep_backups
keep_backups=${keep_backups:-y}

read -p "Keep configuration files (.env, brokers.json)? (y/n) [y]: " keep_config
keep_config=${keep_config:-y}

echo ""
print_section "Starting Uninstall Process"
echo ""

# Count items to remove
items_removed=0

# Stop all running containers
print_info "Stopping XQuantify TradeStation containers..."
if docker-compose down 2>/dev/null; then
    print_success "Containers stopped"
    ((items_removed++))
else
    print_warning "No containers were running or docker-compose.yml not found"
fi

# Remove all XQuantify containers (including scaled instances)
print_info "Removing all XQuantify containers..."
container_count=$(docker ps -a --filter "label=com.xquantify.project=tradestation" -q | wc -l)
if [ "$container_count" -gt 0 ]; then
    docker ps -a --filter "label=com.xquantify.project=tradestation" -q | xargs docker rm -f 2>/dev/null || true
    print_success "Removed $container_count container(s)"
    ((items_removed++))
else
    print_info "No XQuantify containers found"
fi

# Remove Docker images
print_info "Removing XQuantify Docker images..."
image_count=$(docker images --filter "label=com.xquantify.project=tradestation" -q | wc -l)
if [ "$image_count" -gt 0 ]; then
    docker images --filter "label=com.xquantify.project=tradestation" -q | xargs docker rmi -f 2>/dev/null || true
    print_success "Removed $image_count image(s)"
    ((items_removed++))
else
    print_info "No XQuantify images found"
fi

# Remove Docker networks
print_info "Removing XQuantify networks..."
if docker network inspect mt5-network &>/dev/null; then
    docker network rm mt5-network 2>/dev/null || true
    print_success "Removed mt5-network"
    ((items_removed++))
else
    print_info "Network mt5-network not found"
fi

# Remove Docker volumes
print_info "Removing Docker volumes..."
volume_count=$(docker volume ls --filter "label=com.xquantify.project=tradestation" -q 2>/dev/null | wc -l)
if [ "$volume_count" -gt 0 ]; then
    docker volume ls --filter "label=com.xquantify.project=tradestation" -q | xargs docker volume rm 2>/dev/null || true
    print_success "Removed $volume_count volume(s)"
    ((items_removed++))
fi

# Also try to remove named volumes from docker-compose
if docker volume inspect xquantify-tradestation_mt5-data &>/dev/null; then
    docker volume rm xquantify-tradestation_mt5-data 2>/dev/null || true
fi
if docker volume inspect xquantify-tradestation_mt5-logs &>/dev/null; then
    docker volume rm xquantify-tradestation_mt5-logs 2>/dev/null || true
fi

# Remove data directories
if [ "$keep_data" != "y" ]; then
    print_info "Removing MT5 data files..."
    if [ -d "data" ]; then
        rm -rf data/
        print_success "Removed data directory"
        ((items_removed++))
    fi
else
    print_info "Keeping MT5 data files"
fi

# Remove log files
if [ "$keep_logs" != "y" ]; then
    print_info "Removing log files..."
    if [ -d "logs" ]; then
        rm -rf logs/
        print_success "Removed logs directory"
        ((items_removed++))
    fi
else
    print_info "Keeping log files"
fi

# Remove backups
if [ "$keep_backups" != "y" ]; then
    print_info "Removing backups..."
    if [ -d "backups" ]; then
        rm -rf backups/
        print_success "Removed backups directory"
        ((items_removed++))
    fi
else
    print_info "Keeping backup files"
fi

# Remove configuration files
if [ "$keep_config" != "y" ]; then
    print_info "Removing configuration files..."

    # Backup .env before removing
    if [ -f ".env" ]; then
        cp .env .env.uninstall_backup 2>/dev/null || true
        print_info "Backed up .env to .env.uninstall_backup (in case you need it)"
    fi

    rm -f .env .env.backup.* 2>/dev/null || true
    print_success "Removed .env files"
    ((items_removed++))
else
    print_info "Keeping configuration files"
fi

# Remove SSL certificates
print_info "Removing SSL certificates..."
if [ -d "nginx/ssl" ]; then
    rm -rf nginx/ssl/*.pem nginx/ssl/*.key 2>/dev/null || true
    print_success "Removed SSL certificates"
fi

# Clean up Docker system
echo ""
print_section "Docker System Cleanup"
echo ""
print_info "Running Docker system cleanup..."
docker system prune -f &>/dev/null || true
print_success "Docker system cleaned"

# Summary
echo ""
print_section "Uninstall Summary"
echo ""
print_success "XQuantify TradeStation has been uninstalled"
print_info "Items removed/cleaned: $items_removed"

# Show what was kept
echo ""
if [ "$keep_data" = "y" ] || [ "$keep_logs" = "y" ] || [ "$keep_backups" = "y" ] || [ "$keep_config" = "y" ]; then
    print_info "Files preserved:"
    [ "$keep_data" = "y" ] && echo "  ✓ MT5 data files (data/)"
    [ "$keep_logs" = "y" ] && echo "  ✓ Log files (logs/)"
    [ "$keep_backups" = "y" ] && echo "  ✓ Backups (backups/)"
    [ "$keep_config" = "y" ] && echo "  ✓ Configuration files (.env)"
    echo ""
    print_warning "To completely remove all files, delete this directory:"
    echo "  rm -rf $(pwd)"
fi

# Reinstall instructions
echo ""
print_info "To reinstall XQuantify TradeStation:"
echo "  ./install.sh"
echo ""

# Final message
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║           Uninstall Complete - Thank You!                ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

print_success "Done!"
