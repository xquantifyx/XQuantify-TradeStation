#!/bin/bash

# XQuantify TradeStation - Broker Switching Script
# Easily switch between different MT5 brokers

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║         XQuantify TradeStation Broker Switcher           ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if brokers.json exists
if [ ! -f "brokers.json" ]; then
    print_error "brokers.json not found!"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    print_error ".env file not found!"
    print_info "Run './install.sh' first to create configuration"
    exit 1
fi

# Get current broker
CURRENT_BROKER=$(grep "^BROKER=" .env | cut -d'=' -f2)
print_info "Current broker: ${CURRENT_BROKER:-not set}"
echo ""

# Show broker menu
print_info "Available brokers:"
echo ""
echo "  1) MetaQuotes (Official)"
echo "  2) XM Global"
echo "  3) FxPro"
echo "  4) IC Markets"
echo "  5) Pepperstone"
echo "  6) RoboForex"
echo "  7) AvaTrade"
echo "  8) Tickmill"
echo "  9) Admirals"
echo " 10) Exness"
echo " 11) Bybit (Crypto & Derivatives)"
echo " 12) Custom (provide URL)"
echo ""

read -p "Select new broker (1-12): " broker_choice

case $broker_choice in
    1) NEW_BROKER="metaquotes" ;;
    2) NEW_BROKER="xm" ;;
    3) NEW_BROKER="fxpro" ;;
    4) NEW_BROKER="ic_markets" ;;
    5) NEW_BROKER="pepperstone" ;;
    6) NEW_BROKER="roboforex" ;;
    7) NEW_BROKER="avatrade" ;;
    8) NEW_BROKER="tickmill" ;;
    9) NEW_BROKER="admirals" ;;
    10) NEW_BROKER="exness" ;;
    11) NEW_BROKER="bybit" ;;
    12)
        NEW_BROKER="custom"
        read -p "Enter custom MT5 installer URL: " CUSTOM_URL
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Check if already using this broker
if [ "$CURRENT_BROKER" = "$NEW_BROKER" ]; then
    print_warning "Already using $NEW_BROKER broker"
    read -p "Rebuild anyway? (y/n): " rebuild
    if [ "$rebuild" != "y" ]; then
        print_info "No changes made"
        exit 0
    fi
fi

# Backup .env
BACKUP_FILE=".env.backup.$(date +%Y%m%d_%H%M%S)"
cp .env "$BACKUP_FILE"
print_success "Backed up .env to $BACKUP_FILE"

# Update .env file
if grep -q "^BROKER=" .env; then
    sed -i "s/^BROKER=.*/BROKER=$NEW_BROKER/" .env
else
    echo "BROKER=$NEW_BROKER" >> .env
fi

if [ "$NEW_BROKER" = "custom" ]; then
    if grep -q "^MT5_INSTALLER_URL=" .env; then
        sed -i "s|^MT5_INSTALLER_URL=.*|MT5_INSTALLER_URL=$CUSTOM_URL|" .env
    else
        echo "MT5_INSTALLER_URL=$CUSTOM_URL" >> .env
    fi
else
    # Clear custom URL if switching to pre-configured broker
    if grep -q "^MT5_INSTALLER_URL=" .env; then
        sed -i "s|^MT5_INSTALLER_URL=.*|MT5_INSTALLER_URL=|" .env
    fi
fi

print_success "Updated broker configuration to: $NEW_BROKER"
echo ""

# Ask to update MT5 credentials
print_info "Do you want to update MT5 login credentials for this broker?"
read -p "Update credentials? (y/n) [n]: " update_creds
update_creds=${update_creds:-n}

if [ "$update_creds" = "y" ]; then
    read -p "MT5 Login/Account Number: " mt5_login
    read -s -p "MT5 Password: " mt5_password
    echo ""
    read -p "MT5 Server: " mt5_server

    sed -i "s/^MT5_LOGIN=.*/MT5_LOGIN=$mt5_login/" .env
    sed -i "s/^MT5_PASSWORD=.*/MT5_PASSWORD=$mt5_password/" .env
    sed -i "s/^MT5_SERVER=.*/MT5_SERVER=$mt5_server/" .env

    print_success "Updated MT5 credentials"
fi

echo ""
print_info "Next steps:"
echo ""
echo "1. Stop current services:"
echo "   ${GREEN}make stop${NC}"
echo ""
echo "2. Rebuild with new broker:"
echo "   ${GREEN}make build${NC}"
echo ""
echo "3. Start services:"
echo "   ${GREEN}make start${NC}"
echo ""

read -p "Execute these steps now? (y/n) [y]: " execute
execute=${execute:-y}

if [ "$execute" = "y" ]; then
    print_info "Stopping current services..."
    docker-compose down 2>/dev/null || true

    print_info "Building with $NEW_BROKER broker..."
    if [ "$NEW_BROKER" = "custom" ] && [ -n "$CUSTOM_URL" ]; then
        docker-compose build --build-arg MT5_INSTALLER_URL="$CUSTOM_URL"
    else
        docker-compose build --build-arg BROKER="$NEW_BROKER"
    fi

    print_info "Starting services..."
    docker-compose up -d

    echo ""
    print_success "Broker switch complete!"
    echo ""
    print_info "Access your new MT5 setup at:"
    echo "  ${GREEN}http://localhost${NC}"
    echo ""
else
    print_info "Configuration updated. Run the commands above when ready."
fi

print_success "Done!"
