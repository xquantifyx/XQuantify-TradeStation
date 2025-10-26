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

# Check required tools
check_dependencies() {
    print_info "Checking required dependencies..."

    local missing_deps=()

    # Check for openssl
    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi

    # Check for curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Missing dependencies: ${missing_deps[*]}"
        read -p "Install missing dependencies? (y/n): " install_deps

        if [[ $install_deps == "y" ]]; then
            print_info "Installing dependencies..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y "${missing_deps[@]}"
            elif command -v yum &> /dev/null; then
                sudo yum install -y "${missing_deps[@]}"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y "${missing_deps[@]}"
            else
                print_error "Could not detect package manager. Please install manually: ${missing_deps[*]}"
                exit 1
            fi
            print_success "Dependencies installed!"
        else
            print_error "Required dependencies are missing. Please install: ${missing_deps[*]}"
            exit 1
        fi
    else
        print_success "All dependencies found"
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
    print_info "SSL/HTTPS Configuration"
    print_warning "HTTPS is required for full noVNC functionality (clipboard, shortcuts, etc.)"
    echo ""
    echo "SSL Options:"
    echo "  1) Let's Encrypt - FREE trusted certificate (Recommended for production)"
    echo "     • No browser security warnings"
    echo "     • Requires: domain name + port 80 accessible"
    echo "     • Auto-renews every 90 days"
    echo ""
    echo "  2) Self-signed certificate (Quick testing with IP addresses)"
    echo "     • Works immediately without domain"
    echo "     • Browser will show security warning (normal)"
    echo ""
    echo "  3) Skip SSL setup (Not recommended - HTTP only, limited features)"
    echo ""
    read -p "Select SSL option (1-3) [default: 1]: " ssl_option
    ssl_option=${ssl_option:-1}

    case $ssl_option in
        1)
            SSL_ENABLED="true"
            SSL_TYPE="letsencrypt"
            echo ""
            print_info "Let's Encrypt Setup Requirements:"
            echo "  ✓ A domain name (e.g., mt5.yourdomain.com)"
            echo "  ✓ Domain DNS points to this server: $(get_server_ip)"
            echo "  ✓ Port 80 accessible from internet"
            echo ""
            read -p "Enter your domain name (e.g., mt5.example.com): " ssl_domain
            read -p "Enter email for SSL renewal notifications: " ssl_email

            SSL_DOMAIN=$ssl_domain
            SSL_EMAIL=$ssl_email

            if [[ -z "$SSL_DOMAIN" ]] || [[ -z "$SSL_EMAIL" ]]; then
                print_warning "Domain or email not provided. Falling back to self-signed certificate."
                SSL_TYPE="self-signed"
                SSL_DOMAIN=""
                SSL_EMAIL=""
                print_info "Self-signed certificate will be generated (browser warning expected)"
            else
                print_success "Let's Encrypt will be configured for: $SSL_DOMAIN"
                print_info "If Let's Encrypt fails, will auto-fallback to self-signed certificate"
            fi
            ;;
        2)
            SSL_ENABLED="true"
            SSL_TYPE="self-signed"
            SSL_DOMAIN=""
            SSL_EMAIL=""
            print_success "Self-signed SSL certificate will be generated automatically"
            print_warning "Browser will show security warning - click 'Advanced' → 'Proceed'"
            ;;
        3)
            SSL_ENABLED="false"
            SSL_TYPE="none"
            SSL_DOMAIN=""
            SSL_EMAIL=""
            print_warning "SSL disabled - noVNC will have limited functionality"
            print_info "You can enable SSL later with: ./scripts/generate-ssl.sh"
            ;;
        *)
            SSL_ENABLED="true"
            SSL_TYPE="letsencrypt"
            SSL_DOMAIN=""
            SSL_EMAIL=""
            print_warning "Invalid choice. Please provide domain or will use self-signed."
            read -p "Enter domain name (or press Enter for self-signed): " ssl_domain
            if [[ -n "$ssl_domain" ]]; then
                read -p "Enter email for SSL notifications: " ssl_email
                SSL_DOMAIN=$ssl_domain
                SSL_EMAIL=$ssl_email
            else
                SSL_TYPE="self-signed"
                print_info "Using self-signed certificate"
            fi
            ;;
    esac
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
    mkdir -p data logs backups nginx/ssl nginx/certbot/conf nginx/certbot/www configs scripts
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod +x start.sh 2>/dev/null || true
    print_success "Directories created"
}

# Generate self-signed SSL certificate
generate_self_signed_cert() {
    print_info "Generating self-signed SSL certificate..."

    # Detect server IP
    SERVER_IP=$(get_server_ip)

    # Create SSL directory
    mkdir -p nginx/ssl
    cd nginx/ssl

    # Generate certificate
    openssl genrsa -out privkey.pem 4096 2>/dev/null
    openssl req -new -x509 -key privkey.pem -out cert.pem -days 365 \
        -subj "/C=US/ST=State/L=City/O=XQuantify TradeStation/CN=${SERVER_IP}" \
        -addext "subjectAltName=IP:${SERVER_IP},DNS:localhost,IP:127.0.0.1" \
        2>/dev/null

    # Set permissions
    chmod 644 cert.pem
    chmod 600 privkey.pem

    cd ../..

    print_success "Self-signed SSL certificate generated"
    print_info "Certificate location: nginx/ssl/"
    print_warning "Browser will show a security warning (this is normal)"
    print_info "Click 'Advanced' -> 'Proceed' to access the site"
}

# Check for system nginx conflicts
check_system_nginx() {
    print_info "Checking for existing nginx installation..."

    # Check if system nginx is running
    if systemctl is-active --quiet nginx 2>/dev/null; then
        print_warning "System nginx is running"
        SYSTEM_NGINX_RUNNING=true

        # Check which ports it's using
        if command -v ss &> /dev/null; then
            NGINX_PORTS=$(sudo ss -tlnp 2>/dev/null | grep nginx | grep -oP ':\K[0-9]+' | sort -u | tr '\n' ',' | sed 's/,$//')
        else
            NGINX_PORTS="unknown"
        fi

        echo ""
        print_warning "Detected system nginx running on ports: $NGINX_PORTS"
        echo ""
        echo "XQuantify TradeStation will use alternative ports to avoid conflicts:"
        echo "  - HTTP:  Port 8080 (instead of 80)"
        echo "  - HTTPS: Port 8443 (instead of 443)"
        echo ""
        echo "Options:"
        echo "  1) Continue with alternative ports (recommended)"
        echo "  2) Stop system nginx and use standard ports"
        echo "  3) Setup system nginx as reverse proxy (advanced)"
        echo ""
        read -p "Select option (1-3) [default: 1]: " nginx_option
        nginx_option=${nginx_option:-1}

        case $nginx_option in
            1)
                print_info "Using alternative ports 8080/8443"
                USE_ALT_PORTS=true
                SETUP_SYSTEM_PROXY=false
                ;;
            2)
                print_warning "Stopping system nginx..."
                sudo systemctl stop nginx
                sudo systemctl disable nginx
                print_success "System nginx stopped"
                USE_ALT_PORTS=false
                SETUP_SYSTEM_PROXY=false
                SYSTEM_NGINX_RUNNING=false
                ;;
            3)
                print_info "System nginx reverse proxy will be configured after installation"
                USE_ALT_PORTS=true
                SETUP_SYSTEM_PROXY=true
                ;;
            *)
                print_warning "Invalid choice, using alternative ports"
                USE_ALT_PORTS=true
                SETUP_SYSTEM_PROXY=false
                ;;
        esac
    else
        print_success "No system nginx detected"
        SYSTEM_NGINX_RUNNING=false
        USE_ALT_PORTS=false
        SETUP_SYSTEM_PROXY=false
    fi
}

# Check for port conflicts
check_port_conflicts() {
    print_info "Checking for port conflicts..."

    # Check port 80
    if command -v ss &> /dev/null; then
        PORT80=$(sudo ss -tlnp 2>/dev/null | grep ":80 " || true)
    elif command -v netstat &> /dev/null; then
        PORT80=$(sudo netstat -tlnp 2>/dev/null | grep ":80 " || true)
    else
        PORT80=""
    fi

    if [[ -n "$PORT80" ]]; then
        print_warning "Port 80 is in use"
        if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
            print_error "Let's Encrypt requires port 80 to be free"
            print_info "Falling back to self-signed certificate"
            SSL_TYPE="self-signed"
        fi
    fi

    # Check port 443
    if command -v ss &> /dev/null; then
        PORT443=$(sudo ss -tlnp 2>/dev/null | grep ":443 " || true)
    elif command -v netstat &> /dev/null; then
        PORT443=$(sudo netstat -tlnp 2>/dev/null | grep ":443 " || true)
    else
        PORT443=""
    fi

    if [[ -n "$PORT443" ]]; then
        print_warning "Port 443 is in use"
        print_info "Using alternative port 8443 for HTTPS"
    fi
}

# Build and start
build_and_start() {
    echo ""
    read -p "Build and start XQuantify TradeStation now? (y/n) [default: y]: " start_now
    start_now=${start_now:-y}

    if [[ $start_now == "y" ]]; then
        # Check for system nginx conflicts
        check_system_nginx

        # Check for other port conflicts
        check_port_conflicts

        # Generate SSL certificate if needed
        if [[ "$SSL_ENABLED" == "true" ]]; then
            if [[ "$SSL_TYPE" == "self-signed" ]]; then
                echo ""
                generate_self_signed_cert
            fi
        fi

        print_info "Building Docker image (this may take 5-10 minutes on first run)..."

        # Build with broker-specific installer
        if [[ $BROKER_KEY == "custom" ]] && [[ -n $CUSTOM_INSTALLER_URL ]]; then
            docker compose build --build-arg MT5_INSTALLER_URL="$CUSTOM_INSTALLER_URL" || docker-compose build --build-arg MT5_INSTALLER_URL="$CUSTOM_INSTALLER_URL"
        else
            docker compose build --build-arg BROKER="$BROKER_KEY" || docker-compose build --build-arg BROKER="$BROKER_KEY"
        fi

        print_success "Build completed!"

        print_info "Starting services..."
        docker compose up -d || docker-compose up -d

        print_success "Services started!"

        # Setup Let's Encrypt SSL if enabled
        if [[ "$SSL_ENABLED" == "true" ]] && [[ "$SSL_TYPE" == "letsencrypt" ]] && [[ -n "$SSL_DOMAIN" ]]; then
            echo ""
            print_info "Setting up Let's Encrypt SSL certificate..."
            if ./scripts/setup-letsencrypt.sh "$SSL_DOMAIN"; then
                print_success "Let's Encrypt SSL certificate installed"
            else
                print_error "Let's Encrypt setup failed. Falling back to self-signed certificate."
                generate_self_signed_cert
                docker compose restart nginx || docker-compose restart nginx
            fi
        fi

        # Setup system nginx reverse proxy if requested
        if [[ "$SETUP_SYSTEM_PROXY" == "true" ]]; then
            echo ""
            print_info "Setting up system nginx reverse proxy..."
            if ./scripts/setup-system-nginx-proxy.sh; then
                print_success "System nginx reverse proxy configured"
            else
                print_warning "System nginx proxy setup failed - you can set it up manually later"
            fi
        fi

        # Detect server IP
        SERVER_IP=$(get_server_ip)

        echo ""
        print_success "══════════════════════════════════════════════════"
        print_success "    Installation Complete!                       "
        print_success "══════════════════════════════════════════════════"
        echo ""

        # Show access instructions based on configuration
        if [[ "$SYSTEM_NGINX_RUNNING" == "true" && "$SETUP_SYSTEM_PROXY" == "true" ]]; then
            print_info "System Nginx Reverse Proxy Mode:"
            echo ""
            if [[ "$SSL_ENABLED" == "true" ]]; then
                echo -e "  ${GREEN}✓ HTTPS (via system nginx):${NC} https://${SERVER_IP}/vnc.html"
                echo -e "  ${YELLOW}  HTTP (via system nginx):${NC} http://${SERVER_IP}/vnc.html"
                echo ""
                echo -e "  ${BLUE}Direct access (bypass nginx):${NC}"
                echo -e "    HTTPS: https://${SERVER_IP}:8443/vnc.html"
                echo -e "    HTTP:  http://${SERVER_IP}:8080/vnc.html"
            else
                echo -e "  ${YELLOW}HTTP (via system nginx):${NC} http://${SERVER_IP}/vnc.html"
                echo -e "  ${BLUE}Direct: http://${SERVER_IP}:8080/vnc.html"
            fi
        else
            print_info "Access your MT5 platform:"
            echo ""
            if [[ "$SSL_ENABLED" == "true" ]]; then
                if [[ -n "$SSL_DOMAIN" && "$SSL_TYPE" == "letsencrypt" ]]; then
                    # Let's Encrypt with domain - show clean URLs
                    echo -e "  ${GREEN}✓ HTTPS (Trusted Certificate):${NC}"
                    echo -e "    https://${SSL_DOMAIN}:8443/vnc.html"
                    echo -e "    ${BLUE}(No browser warnings!)${NC}"
                    echo ""
                    echo -e "  ${YELLOW}Alternative access:${NC}"
                    echo -e "    http://${SSL_DOMAIN}:8080/vnc.html (HTTP)"
                    echo -e "    https://${SERVER_IP}:8443/vnc.html (IP-based)"
                elif [[ -n "$SSL_DOMAIN" ]]; then
                    # Domain provided but not Let's Encrypt
                    echo -e "  ${GREEN}✓ HTTPS:${NC} https://${SSL_DOMAIN}:8443/vnc.html"
                    echo -e "  ${YELLOW}  HTTP:${NC} http://${SSL_DOMAIN}:8080/vnc.html"
                else
                    # IP-based (self-signed)
                    echo -e "  ${GREEN}✓ HTTPS (Recommended):${NC}"
                    echo -e "    https://${SERVER_IP}:8443/vnc.html"
                    echo ""
                    echo -e "  ${YELLOW}Alternative access:${NC}"
                    echo -e "    http://${SERVER_IP}:8080/vnc.html (HTTP)"
                    echo -e "    http://${SERVER_IP}:6080/vnc.html (Direct)"
                fi
                echo ""
                if [[ "$SSL_TYPE" == "self-signed" ]]; then
                    print_warning "Using self-signed certificate - browser will show security warning"
                    print_info "To proceed: Click 'Advanced' → 'Proceed to ${SERVER_IP} (unsafe)'"
                    print_info "This is NORMAL and SAFE for self-signed certificates"
                    echo ""
                    print_info "For production with trusted certificate, use Let's Encrypt:"
                    echo "  ./scripts/setup-letsencrypt.sh yourdomain.com"
                elif [[ "$SSL_TYPE" == "letsencrypt" ]]; then
                    print_success "Let's Encrypt certificate installed - no browser warnings!"
                fi
            else
                echo -e "  ${YELLOW}HTTP:${NC} http://${SERVER_IP}:8080/vnc.html"
                echo -e "  ${YELLOW}Direct:${NC} http://${SERVER_IP}:6080/vnc.html"
                echo ""
                print_warning "HTTPS not enabled - limited noVNC features"
                print_info "Enable HTTPS: ./scripts/generate-ssl.sh"
            fi
        fi
        echo ""
        print_info "VNC Password: ${GREEN}$VNC_PASSWORD${NC}"
        echo ""

        # Firewall configuration
        print_info "Firewall Configuration:"
        if [[ "$SSL_ENABLED" == "true" ]]; then
            echo "  sudo ufw allow 8080/tcp   # HTTP"
            echo "  sudo ufw allow 8443/tcp   # HTTPS"
            echo "  sudo ufw allow 6080/tcp   # Direct access"
        else
            echo "  sudo ufw allow 8080/tcp   # HTTP"
            echo "  sudo ufw allow 6080/tcp   # Direct access"
        fi
        echo ""

        print_info "Useful Commands:"
        echo "  docker compose ps              # Check container status"
        echo "  docker compose logs -f nginx   # View nginx logs"
        echo "  docker compose restart nginx   # Restart nginx"
        echo "  docker compose down            # Stop all services"
        echo "  docker compose up -d           # Start all services"
        echo ""
        if command -v make &> /dev/null; then
            echo "  Or install 'make' for shortcuts:"
            echo "    apt install make -y"
            echo "  Then use: make status, make logs, make restart, etc."
            echo ""
        fi
        print_success "Setup complete! Enjoy your MT5 TradeStation!"
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
    check_dependencies
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
