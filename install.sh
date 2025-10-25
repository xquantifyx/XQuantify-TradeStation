#!/bin/bash

# XQuantify TradeStation - Quick Install Script
# One-command installation with interactive setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║           XQuantify TradeStation Installer               ║
║        Professional MT5 Docker Deployment Platform       ║
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

# Check if running on Windows (Git Bash, WSL, etc.)
check_platform() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        print_error "Windows native detected. Please use WSL2 or install Docker Desktop."
        print_info "Installation guide: https://docs.docker.com/desktop/install/windows-install/"
        exit 1
    fi
}

# Check Docker installation
check_docker() {
    print_info "Checking Docker installation..."

    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found!"
        read -p "Install Docker automatically? (y/n): " install_docker

        if [[ $install_docker == "y" ]]; then
            print_info "Installing Docker..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
            print_success "Docker installed! Please log out and back in, then re-run this script."
            exit 0
        else
            print_error "Docker is required. Install it manually from: https://docs.docker.com/get-docker/"
            exit 1
        fi
    else
        print_success "Docker found: $(docker --version)"
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker and try again."
        exit 1
    fi
}

# Check Docker Compose
check_docker_compose() {
    print_info "Checking Docker Compose installation..."

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_warning "Docker Compose not found!"
        read -p "Install Docker Compose automatically? (y/n): " install_compose

        if [[ $install_compose == "y" ]]; then
            print_info "Installing Docker Compose..."
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            print_success "Docker Compose installed!"
        else
            print_error "Docker Compose is required."
            exit 1
        fi
    else
        print_success "Docker Compose found"
    fi
}

# Interactive broker selection
select_broker() {
    echo ""
    print_info "Select your MT5 broker:"
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
    echo " 12) Custom (provide your own installer URL)"
    echo ""

    read -p "Enter broker number (1-12) [default: 1]: " broker_choice
    broker_choice=${broker_choice:-1}

    case $broker_choice in
        1) BROKER_KEY="metaquotes" ;;
        2) BROKER_KEY="xm" ;;
        3) BROKER_KEY="fxpro" ;;
        4) BROKER_KEY="ic_markets" ;;
        5) BROKER_KEY="pepperstone" ;;
        6) BROKER_KEY="roboforex" ;;
        7) BROKER_KEY="avatrade" ;;
        8) BROKER_KEY="tickmill" ;;
        9) BROKER_KEY="admirals" ;;
        10) BROKER_KEY="exness" ;;
        11) BROKER_KEY="bybit" ;;
        12)
            BROKER_KEY="custom"
            read -p "Enter your custom MT5 installer URL: " CUSTOM_INSTALLER_URL
            ;;
        *)
            print_warning "Invalid choice, using MetaQuotes (Official)"
            BROKER_KEY="metaquotes"
            ;;
    esac

    print_success "Selected broker: $BROKER_KEY"
}

# Configure installation
configure_installation() {
    echo ""
    print_info "Configuration Setup"
    echo ""

    # VNC Password
    read -p "Set VNC password [default: mt5password]: " vnc_password
    VNC_PASSWORD=${vnc_password:-mt5password}

    # Ask if user wants auto-login
    read -p "Configure MT5 auto-login? (y/n) [default: n]: " auto_login
    auto_login=${auto_login:-n}

    if [[ $auto_login == "y" ]]; then
        read -p "MT5 Login/Account Number: " mt5_login
        read -s -p "MT5 Password: " mt5_password
        echo ""
        read -p "MT5 Server: " mt5_server

        MT5_LOGIN=$mt5_login
        MT5_PASSWORD=$mt5_password
        MT5_SERVER=$mt5_server
    else
        MT5_LOGIN=""
        MT5_PASSWORD=""
        MT5_SERVER=""
    fi

    # Performance settings
    echo ""
    read -p "Number of CPU cores per instance [default: 2]: " cpu_cores
    WINE_CPU_CORES=${cpu_cores:-2}

    read -p "Memory limit per instance (e.g., 2g, 4g) [default: 2g]: " memory_limit
    WINE_MEMORY_LIMIT=${memory_limit:-2g}

    # Monitoring
    read -p "Enable monitoring? (y/n) [default: y]: " enable_monitoring
    enable_monitoring=${enable_monitoring:-y}
    if [[ $enable_monitoring == "y" ]]; then
        ENABLE_MONITORING="true"
    else
        ENABLE_MONITORING="false"
    fi

    # SSL Configuration
    echo ""
    print_info "SSL Configuration (HTTPS)"
    read -p "Enable SSL with Let's Encrypt? (y/n) [default: n]: " enable_ssl
    enable_ssl=${enable_ssl:-n}

    if [[ $enable_ssl == "y" ]]; then
        SSL_ENABLED="true"
        print_warning "Let's Encrypt requires:"
        echo "  - A valid domain name (not IP address)"
        echo "  - Domain pointing to this server's public IP"
        echo "  - Port 80 accessible from internet"
        echo ""
        read -p "Enter your domain name (e.g., mt5.example.com): " ssl_domain
        read -p "Enter email for SSL notifications: " ssl_email

        SSL_DOMAIN=$ssl_domain
        SSL_EMAIL=$ssl_email
        SETUP_SSL_LATER=false

        if [[ -z "$SSL_DOMAIN" ]] || [[ -z "$SSL_EMAIL" ]]; then
            print_warning "Domain or email not provided. SSL setup will be skipped."
            print_info "You can set up SSL later using: ./scripts/setup-letsencrypt.sh"
            SSL_ENABLED="false"
            SETUP_SSL_LATER=true
        fi
    else
        SSL_ENABLED="false"
        SSL_DOMAIN=""
        SSL_EMAIL=""
        SETUP_SSL_LATER=false
        print_info "SSL disabled. You can enable it later with: ./scripts/setup-letsencrypt.sh"
    fi
}

# Create .env file
create_env_file() {
    print_info "Creating .env configuration file..."

    # Backup existing .env if it exists
    if [ -f .env ]; then
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        print_warning "Existing .env backed up"
    fi

    cat > .env << EOF
# XQuantify TradeStation Configuration
# Generated on $(date)

# Broker Configuration
BROKER=$BROKER_KEY
MT5_INSTALLER_URL=${CUSTOM_INSTALLER_URL:-}

# VNC Configuration
VNC_PASSWORD=$VNC_PASSWORD
DISPLAY=:1

# MetaTrader 5 Login Credentials (optional)
MT5_LOGIN=$MT5_LOGIN
MT5_PASSWORD=$MT5_PASSWORD
MT5_SERVER=$MT5_SERVER

# Scaling Configuration
MAX_INSTANCES=10
AUTO_SCALE=false
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80

# Monitoring Configuration
ENABLE_MONITORING=$ENABLE_MONITORING
CHECK_INTERVAL=30
ALERT_EMAIL=
WEBHOOK_URL=

# Backup Configuration
BACKUP_RETENTION_DAYS=30
AUTO_BACKUP=false
BACKUP_SCHEDULE="0 2 * * *"

# Network Configuration
NETWORK_NAME=mt5-network
SUBNET=172.20.0.0/16

# Storage Configuration
DATA_PATH=./data
LOGS_PATH=./logs
BACKUP_PATH=./backups

# SSL Configuration (for nginx)
SSL_ENABLED=$SSL_ENABLED
SSL_DOMAIN=$SSL_DOMAIN
SSL_EMAIL=$SSL_EMAIL
SSL_CERT_PATH=./nginx/ssl/cert.pem
SSL_KEY_PATH=./nginx/ssl/privkey.pem

# Performance Tuning
XVFB_RESOLUTION=1920x1080x24
WINE_CPU_CORES=$WINE_CPU_CORES
WINE_MEMORY_LIMIT=$WINE_MEMORY_LIMIT

# Security
ENABLE_FIREWALL=true
ALLOWED_IPS=127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12

# Timezone
TZ=UTC
EOF

    print_success ".env file created"
}

# Detect server IP address
get_server_ip() {
    # Try to get public IP first
    PUBLIC_IP=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || echo "")

    # Get local IP as fallback
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 2>/dev/null | awk '{print $7}' || echo "localhost")

    # Use public IP if available, otherwise local IP
    if [[ -n "$PUBLIC_IP" ]]; then
        echo "$PUBLIC_IP"
    else
        echo "$LOCAL_IP"
    fi
}

# Setup directories
setup_directories() {
    print_info "Creating required directories..."
    mkdir -p data logs backups nginx/ssl configs scripts
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod +x start.sh 2>/dev/null || true
    print_success "Directories created"
}

# Build and start
build_and_start() {
    echo ""
    read -p "Build and start XQuantify TradeStation now? (y/n) [default: y]: " start_now
    start_now=${start_now:-y}

    if [[ $start_now == "y" ]]; then
        print_info "Building Docker image (this may take 5-10 minutes on first run)..."

        # Build with broker-specific installer
        if [[ $BROKER_KEY == "custom" ]] && [[ -n $CUSTOM_INSTALLER_URL ]]; then
            docker-compose build --build-arg MT5_INSTALLER_URL="$CUSTOM_INSTALLER_URL"
        else
            docker-compose build --build-arg BROKER="$BROKER_KEY"
        fi

        print_success "Build completed!"

        print_info "Starting services..."
        docker-compose up -d

        print_success "Services started!"

        # Setup SSL if enabled
        if [[ "$SSL_ENABLED" == "true" ]] && [[ -n "$SSL_DOMAIN" ]]; then
            echo ""
            print_info "Setting up Let's Encrypt SSL certificate..."
            ./scripts/setup-letsencrypt.sh "$SSL_DOMAIN"
        fi

        # Detect server IP
        SERVER_IP=$(get_server_ip)

        echo ""
        print_success "Installation complete!"
        echo ""
        print_info "Access your MT5 platform at:"
        if [[ "$SSL_ENABLED" == "true" ]] && [[ -n "$SSL_DOMAIN" ]]; then
            echo -e "  ${GREEN}https://${SSL_DOMAIN}:8443${NC} (HTTPS via nginx)"
            echo -e "  ${GREEN}http://${SERVER_IP}:8080${NC} (HTTP via nginx)"
        else
            echo -e "  ${GREEN}http://${SERVER_IP}:8080${NC} (via nginx load balancer)"
        fi
        echo -e "  ${GREEN}http://${SERVER_IP}:6080${NC} (direct access)"
        echo ""
        print_info "VNC Password: $VNC_PASSWORD"
        echo ""
        if [[ "$SSL_ENABLED" == "true" ]]; then
            print_warning "Note: Make sure ports 80, 443, 6080, and 8080/8443 are open in your firewall!"
            print_info "To open ports, run:"
            echo "  sudo ufw allow 80/tcp"
            echo "  sudo ufw allow 443/tcp"
            echo "  sudo ufw allow 6080/tcp"
            echo "  sudo ufw allow 8080/tcp"
            echo "  sudo ufw allow 8443/tcp"
        else
            print_warning "Note: Make sure ports 6080 and 8080 are open in your firewall!"
            print_info "To open ports, run:"
            echo "  sudo ufw allow 6080/tcp"
            echo "  sudo ufw allow 8080/tcp"
        fi
        echo ""
        print_info "Useful commands:"
        echo "  make status    - Check instance status"
        echo "  make logs      - View logs"
        echo "  make scale N=3 - Scale to 3 instances"
        echo "  make stop      - Stop all services"
        echo ""
    else
        echo ""
        print_success "Configuration complete!"
        print_info "To build and start manually, run:"
        echo "  make build"
        echo "  make start"
        echo ""
    fi
}

# Main installation flow
main() {
    echo ""
    print_info "Starting XQuantify TradeStation installation..."
    echo ""

    # Platform check
    # check_platform  # Commented out for WSL2/Windows compatibility

    # Check dependencies
    check_docker
    check_docker_compose

    # Interactive setup
    select_broker
    configure_installation

    # Create configuration
    create_env_file
    setup_directories

    # Build and start
    build_and_start

    print_success "Setup wizard completed!"
}

# Run main function
main
