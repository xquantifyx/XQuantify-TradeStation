#!/bin/bash

# XQuantify TradeStation - Let's Encrypt SSL Auto-Setup
# Automatically provisions and renews SSL certificates using Certbot
# Handles port 80 conflicts automatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════╗
║   XQuantify TradeStation - Let's Encrypt SSL  ║
║      Production SSL Certificate Setup         ║
╚════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Check Docker installation
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if domain is provided
if [ -z "$1" ]; then
    echo ""
    print_info "Let's Encrypt requires a valid domain name (not an IP address)."
    print_info "Make sure your domain points to this server's public IP."
    echo ""
    read -p "Enter your domain name (e.g., mt5.example.com): " DOMAIN
else
    DOMAIN=$1
fi

if [ -z "$DOMAIN" ]; then
    print_error "Domain name is required for Let's Encrypt SSL."
    exit 1
fi

# Get email for Let's Encrypt notifications
if [ -z "$2" ]; then
    read -p "Enter email address for SSL certificate notifications: " EMAIL
else
    EMAIL=$2
fi

if [ -z "$EMAIL" ]; then
    print_error "Email address is required for Let's Encrypt."
    exit 1
fi

# Validate domain format
if [[ ! $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    print_error "Invalid domain format. Please provide a valid domain name."
    exit 1
fi

# Get server's public IP
PUBLIC_IP=$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null || echo "")
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")
fi

echo ""
print_info "Domain: $DOMAIN"
print_info "Email: $EMAIL"
print_info "Server IP: $PUBLIC_IP"
echo ""

# Verify DNS is pointing to this server
print_info "Verifying DNS configuration..."
DOMAIN_IP=$(dig +short "$DOMAIN" 2>/dev/null | head -1 || echo "")

if [ -z "$DOMAIN_IP" ]; then
    print_warning "Cannot resolve domain $DOMAIN"
    echo ""
    print_info "Please ensure:"
    echo "  1. DNS A record exists: $DOMAIN → $PUBLIC_IP"
    echo "  2. DNS has propagated (may take 5-15 minutes)"
    echo ""
    read -p "Continue anyway? (y/n) [default: y]: " continue_dns
    continue_dns=${continue_dns:-y}
    if [[ $continue_dns != "y" ]]; then
        print_error "Aborted. Please configure DNS first."
        exit 1
    fi
elif [ "$DOMAIN_IP" != "$PUBLIC_IP" ]; then
    print_warning "Domain IP ($DOMAIN_IP) doesn't match server IP ($PUBLIC_IP)"
    echo ""
    print_info "This may cause Let's Encrypt validation to fail."
    print_info "Please update your DNS A record: $DOMAIN → $PUBLIC_IP"
    echo ""
    read -p "Continue anyway? (y/n) [default: n]: " continue_mismatch
    continue_mismatch=${continue_mismatch:-n}
    if [[ $continue_mismatch != "y" ]]; then
        print_error "Aborted. Please fix DNS configuration first."
        exit 1
    fi
else
    print_success "DNS configured correctly: $DOMAIN → $DOMAIN_IP"
fi

# Create necessary directories
print_info "Creating SSL directories..."
mkdir -p nginx/ssl
mkdir -p nginx/certbot/conf
mkdir -p nginx/certbot/www

# Check if port 80 is in use
print_info "Checking port 80 availability..."
PORT80_IN_USE=false
PORT80_SERVICE=""

if command -v ss &> /dev/null; then
    PORT80_CHECK=$(${SUDO} ss -tlnp 2>/dev/null | grep ":80 " || true)
elif command -v netstat &> /dev/null; then
    PORT80_CHECK=$(${SUDO} netstat -tlnp 2>/dev/null | grep ":80 " || true)
else
    PORT80_CHECK=""
fi

if [ -n "$PORT80_CHECK" ]; then
    PORT80_IN_USE=true
    # Try to identify the service
    if echo "$PORT80_CHECK" | grep -q "nginx"; then
        PORT80_SERVICE="nginx"
    elif echo "$PORT80_CHECK" | grep -q "apache"; then
        PORT80_SERVICE="apache"
    elif echo "$PORT80_CHECK" | grep -q "httpd"; then
        PORT80_SERVICE="httpd"
    else
        PORT80_SERVICE="unknown"
    fi
fi

# Determine the best method for Let's Encrypt
CERTBOT_METHOD=""
SYSTEM_NGINX_RUNNING=false

if [ "$PORT80_IN_USE" = true ]; then
    print_warning "Port 80 is already in use by: $PORT80_SERVICE"
    echo ""

    # Check if it's system nginx
    if systemctl is-active --quiet nginx 2>/dev/null; then
        SYSTEM_NGINX_RUNNING=true
        print_info "System nginx detected. Using webroot method..."
        CERTBOT_METHOD="webroot"
    else
        print_warning "Port 80 is in use but not by system nginx."
        echo ""
        echo "Options:"
        echo "  1) Temporarily stop the service using port 80"
        echo "  2) Use DNS challenge (requires manual DNS TXT record)"
        echo "  3) Cancel and configure manually"
        echo ""
        read -p "Select option (1-3) [default: 1]: " port_option
        port_option=${port_option:-1}

        case $port_option in
            1)
                print_info "Will temporarily stop $PORT80_SERVICE..."
                CERTBOT_METHOD="standalone"
                STOP_SERVICE=true
                ;;
            2)
                print_info "Using DNS challenge method..."
                CERTBOT_METHOD="dns"
                ;;
            3)
                print_error "Aborted by user."
                exit 1
                ;;
            *)
                print_warning "Invalid option. Using standalone method."
                CERTBOT_METHOD="standalone"
                STOP_SERVICE=true
                ;;
        esac
    fi
else
    print_success "Port 80 is available"
    CERTBOT_METHOD="standalone"
fi

# Check if Docker nginx is running
DOCKER_NGINX_RUNNING=$(docker ps --filter "name=xquantify-tradestation-nginx" --format "{{.Names}}" 2>/dev/null || echo "")

if [ -n "$DOCKER_NGINX_RUNNING" ]; then
    print_info "Stopping Docker nginx temporarily..."
    docker stop xquantify-tradestation-nginx >/dev/null 2>&1
    RESTART_DOCKER_NGINX=true
else
    RESTART_DOCKER_NGINX=false
fi

# Execute Let's Encrypt certificate request based on method
echo ""
print_info "Obtaining SSL certificate from Let's Encrypt..."
print_info "Method: $CERTBOT_METHOD"
print_warning "This may take a few moments. Please be patient..."
echo ""

SUCCESS=false

case $CERTBOT_METHOD in
    webroot)
        # Use webroot method with system nginx
        print_info "Configuring system nginx for ACME challenge..."

        # Create webroot directory
        ${SUDO} mkdir -p /var/www/certbot

        # Create temporary nginx configuration for ACME challenge
        TEMP_NGINX_CONF="/etc/nginx/sites-available/certbot-challenge"

        ${SUDO} tee "$TEMP_NGINX_CONF" > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

        # Enable the configuration
        ${SUDO} ln -sf "$TEMP_NGINX_CONF" /etc/nginx/sites-enabled/certbot-challenge

        # Test and reload nginx
        if ${SUDO} nginx -t 2>/dev/null; then
            ${SUDO} systemctl reload nginx
            print_success "System nginx configured for ACME challenge"
        else
            print_error "Nginx configuration test failed"
            ${SUDO} rm -f /etc/nginx/sites-enabled/certbot-challenge
            exit 1
        fi

        # Run certbot with webroot
        if docker run --rm \
            -v "$(pwd)/nginx/certbot/conf:/etc/letsencrypt" \
            -v "/var/www/certbot:/var/www/certbot" \
            certbot/certbot certonly \
            --webroot \
            --webroot-path=/var/www/certbot \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            -d "$DOMAIN"; then
            SUCCESS=true
            print_success "Certificate obtained successfully!"
        else
            print_error "Failed to obtain certificate via webroot method"
        fi

        # Cleanup
        ${SUDO} rm -f /etc/nginx/sites-enabled/certbot-challenge
        ${SUDO} systemctl reload nginx 2>/dev/null || true
        ;;

    standalone)
        # Stop conflicting service if needed
        if [ "$STOP_SERVICE" = true ]; then
            print_info "Stopping $PORT80_SERVICE..."

            if [ "$PORT80_SERVICE" = "nginx" ]; then
                ${SUDO} systemctl stop nginx
            elif [ "$PORT80_SERVICE" = "apache" ] || [ "$PORT80_SERVICE" = "httpd" ]; then
                ${SUDO} systemctl stop apache2 2>/dev/null || ${SUDO} systemctl stop httpd 2>/dev/null || true
            fi

            sleep 2
        fi

        # Use standalone method
        if docker run --rm \
            -v "$(pwd)/nginx/certbot/conf:/etc/letsencrypt" \
            -v "$(pwd)/nginx/certbot/www:/var/www/certbot" \
            -p 80:80 \
            certbot/certbot certonly \
            --standalone \
            --preferred-challenges http \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            -d "$DOMAIN"; then
            SUCCESS=true
            print_success "Certificate obtained successfully!"
        else
            print_error "Failed to obtain certificate via standalone method"
        fi

        # Restart service if we stopped it
        if [ "$STOP_SERVICE" = true ]; then
            print_info "Restarting $PORT80_SERVICE..."

            if [ "$PORT80_SERVICE" = "nginx" ]; then
                ${SUDO} systemctl start nginx
            elif [ "$PORT80_SERVICE" = "apache" ] || [ "$PORT80_SERVICE" = "httpd" ]; then
                ${SUDO} systemctl start apache2 2>/dev/null || ${SUDO} systemctl start httpd 2>/dev/null || true
            fi
        fi
        ;;

    dns)
        # Use DNS challenge (manual)
        print_info "Using DNS challenge method..."
        print_warning "You will need to add a TXT record to your DNS"
        echo ""

        docker run --rm -it \
            -v "$(pwd)/nginx/certbot/conf:/etc/letsencrypt" \
            certbot/certbot certonly \
            --manual \
            --preferred-challenges dns \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            -d "$DOMAIN"

        if [ $? -eq 0 ]; then
            SUCCESS=true
            print_success "Certificate obtained successfully!"
        else
            print_error "Failed to obtain certificate via DNS challenge"
        fi
        ;;
esac

# Check if certificate was obtained
if [ "$SUCCESS" = false ]; then
    print_error "Failed to obtain SSL certificate."
    echo ""
    print_info "Troubleshooting tips:"
    echo "  1. Verify DNS: dig +short $DOMAIN"
    echo "  2. Check firewall: ${SUDO} ufw status"
    echo "  3. Test port 80: curl -I http://$DOMAIN"
    echo "  4. Review logs above for specific error"
    echo ""
    print_info "Alternative: Use self-signed certificate"
    echo "  ./scripts/generate-ssl.sh"
    echo ""

    # Restart Docker nginx if needed
    if [ "$RESTART_DOCKER_NGINX" = true ]; then
        docker start xquantify-tradestation-nginx >/dev/null 2>&1
    fi

    exit 1
fi

# Create symlinks for nginx
print_info "Creating certificate symlinks..."
ln -sf "$(pwd)/nginx/certbot/conf/live/$DOMAIN/fullchain.pem" nginx/ssl/cert.pem
ln -sf "$(pwd)/nginx/certbot/conf/live/$DOMAIN/privkey.pem" nginx/ssl/privkey.pem
print_success "Certificates linked to nginx/ssl/"

# Update .env file
print_info "Updating .env configuration..."
if [ -f .env ]; then
    # Update existing entries or add new ones
    if grep -q "^SSL_ENABLED=" .env; then
        sed -i.bak 's/^SSL_ENABLED=.*/SSL_ENABLED=true/' .env
    else
        echo "SSL_ENABLED=true" >> .env
    fi

    if grep -q "^SSL_TYPE=" .env; then
        sed -i.bak 's/^SSL_TYPE=.*/SSL_TYPE=letsencrypt/' .env
    else
        echo "SSL_TYPE=letsencrypt" >> .env
    fi

    if grep -q "^SSL_DOMAIN=" .env; then
        sed -i.bak "s/^SSL_DOMAIN=.*/SSL_DOMAIN=$DOMAIN/" .env
    else
        echo "SSL_DOMAIN=$DOMAIN" >> .env
    fi

    if grep -q "^SSL_EMAIL=" .env; then
        sed -i.bak "s/^SSL_EMAIL=.*/SSL_EMAIL=$EMAIL/" .env
    else
        echo "SSL_EMAIL=$EMAIL" >> .env
    fi

    print_success "Configuration updated"
fi

# Create renewal script
print_info "Creating certificate renewal script..."
cat > scripts/renew-ssl.sh << 'RENEWAL_SCRIPT'
#!/bin/bash

# XQuantify TradeStation - SSL Certificate Renewal
# Automatically renews Let's Encrypt certificates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs 2>/dev/null || true)
fi

# Check if SSL is enabled
if [ "$SSL_ENABLED" != "true" ]; then
    echo "SSL is not enabled. Skipping renewal."
    exit 0
fi

echo "Checking for certificate renewal..."

# Renew certificates using Certbot
docker run --rm \
    -v "$(pwd)/nginx/certbot/conf:/etc/letsencrypt" \
    -v "$(pwd)/nginx/certbot/www:/var/www/certbot" \
    certbot/certbot renew \
    --quiet \
    --deploy-hook "echo 'Certificate renewed successfully!'"

# Reload nginx to use new certificates
if docker ps --filter "name=xquantify-tradestation-nginx" --format "{{.Names}}" | grep -q "xquantify-tradestation-nginx"; then
    echo "Reloading nginx..."
    docker exec xquantify-tradestation-nginx nginx -s reload 2>/dev/null || docker restart xquantify-tradestation-nginx
    echo "SSL certificates checked/renewed and nginx reloaded!"
else
    echo "SSL certificates checked/renewed. Restart nginx when ready."
fi
RENEWAL_SCRIPT

chmod +x scripts/renew-ssl.sh
print_success "Renewal script created: scripts/renew-ssl.sh"

# Setup auto-renewal via cron
print_info "Setting up automatic renewal..."
CRON_JOB="0 3 * * * cd $(pwd) && ./scripts/renew-ssl.sh >> logs/ssl-renewal.log 2>&1"

if crontab -l 2>/dev/null | grep -q "renew-ssl.sh"; then
    print_warning "Cron job already exists"
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab - 2>/dev/null && \
        print_success "Auto-renewal scheduled (daily at 3 AM)" || \
        print_warning "Could not create cron job. Set up manually if needed."
fi

# Restart Docker nginx
if [ "$RESTART_DOCKER_NGINX" = true ]; then
    print_info "Starting Docker nginx with SSL..."
    docker start xquantify-tradestation-nginx >/dev/null 2>&1
    sleep 2
    print_success "Docker nginx started"
fi

# Final summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Let's Encrypt SSL Setup Complete!         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
print_info "Certificate Details:"
echo "  ✓ Domain: $DOMAIN"
echo "  ✓ Email: $EMAIL"
echo "  ✓ Type: Let's Encrypt (Trusted)"
echo "  ✓ Expires: 90 days (auto-renews)"
echo "  ✓ Certificate: nginx/ssl/cert.pem"
echo "  ✓ Private Key: nginx/ssl/privkey.pem"
echo ""
print_success "Access your MT5 platform:"
echo -e "  ${GREEN}✓ https://$DOMAIN:8443/vnc.html${NC}"
echo -e "  ${BLUE}  (No browser warnings!)${NC}"
echo ""
if [ "$SYSTEM_NGINX_RUNNING" = true ]; then
    print_info "System nginx detected. You can also setup reverse proxy:"
    echo "  ${SUDO} ./scripts/setup-system-nginx-proxy.sh"
    echo "  Then access via: https://$DOMAIN/vnc.html (standard port 443)"
    echo ""
fi
print_info "Firewall Configuration:"
echo "  ${SUDO} ufw allow 8443/tcp   # HTTPS"
echo "  ${SUDO} ufw allow 8080/tcp   # HTTP"
echo ""
print_info "Certificate Management:"
echo "  • Auto-renewal: Daily check at 3 AM"
echo "  • Manual renewal: ./scripts/renew-ssl.sh"
echo "  • Check status: docker run --rm -v \$(pwd)/nginx/certbot/conf:/etc/letsencrypt certbot/certbot certificates"
echo ""
print_success "Setup complete! Enjoy your trusted SSL certificate!"
echo ""
