#!/bin/bash

# XQuantify TradeStation - Let's Encrypt SSL Auto-Setup
# Automatically provisions and renews SSL certificates using Certbot

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
║           Automatic SSL Certificate Setup     ║
╚════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
    print_info "This script may require sudo privileges for certain operations."
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
read -p "Enter email address for SSL certificate notifications: " EMAIL

if [ -z "$EMAIL" ]; then
    print_error "Email address is required for Let's Encrypt."
    exit 1
fi

# Validate domain format
if [[ ! $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    print_error "Invalid domain format. Please provide a valid domain name."
    exit 1
fi

# Create necessary directories
print_info "Creating SSL directories..."
mkdir -p nginx/ssl
mkdir -p nginx/certbot/conf
mkdir -p nginx/certbot/www

# Check if nginx is running
NGINX_RUNNING=$(docker ps --filter "name=xquantify-tradestation-nginx" --format "{{.Names}}" 2>/dev/null || echo "")

if [ -n "$NGINX_RUNNING" ]; then
    print_warning "Nginx container is running. Stopping it temporarily for SSL setup..."
    docker stop xquantify-tradestation-nginx
    RESTART_NGINX=true
else
    RESTART_NGINX=false
fi

# Run Certbot to obtain certificate
print_info "Obtaining SSL certificate from Let's Encrypt..."
print_warning "This may take a few moments. Please be patient..."

# Use Certbot docker container for certificate generation
docker run --rm -it \
    -v "$(pwd)/nginx/certbot/conf:/etc/letsencrypt" \
    -v "$(pwd)/nginx/certbot/www:/var/www/certbot" \
    -p 80:80 \
    certbot/certbot certonly \
    --standalone \
    --preferred-challenges http \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

if [ $? -ne 0 ]; then
    print_error "Failed to obtain SSL certificate."
    print_info "Please check:"
    echo "  1. Your domain ($DOMAIN) points to this server's public IP"
    echo "  2. Port 80 is accessible from the internet"
    echo "  3. No firewall is blocking HTTP traffic"

    if [ "$RESTART_NGINX" = true ]; then
        docker start xquantify-tradestation-nginx
    fi
    exit 1
fi

print_success "SSL certificate obtained successfully!"

# Create symlinks for nginx
print_info "Creating certificate symlinks for nginx..."
ln -sf "$(pwd)/nginx/certbot/conf/live/$DOMAIN/fullchain.pem" nginx/ssl/cert.pem
ln -sf "$(pwd)/nginx/certbot/conf/live/$DOMAIN/privkey.pem" nginx/ssl/privkey.pem

# Update .env file to enable SSL
print_info "Updating .env configuration..."
if grep -q "^SSL_ENABLED=" .env 2>/dev/null; then
    sed -i.bak 's/^SSL_ENABLED=.*/SSL_ENABLED=true/' .env
    print_success "SSL enabled in .env"
else
    echo "SSL_ENABLED=true" >> .env
    print_success "SSL_ENABLED added to .env"
fi

if grep -q "^SSL_DOMAIN=" .env 2>/dev/null; then
    sed -i.bak "s/^SSL_DOMAIN=.*/SSL_DOMAIN=$DOMAIN/" .env
else
    echo "SSL_DOMAIN=$DOMAIN" >> .env
fi

if grep -q "^SSL_EMAIL=" .env 2>/dev/null; then
    sed -i.bak "s/^SSL_EMAIL=.*/SSL_EMAIL=$EMAIL/" .env
else
    echo "SSL_EMAIL=$EMAIL" >> .env
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
    export $(grep -v '^#' .env | xargs)
fi

# Check if SSL is enabled
if [ "$SSL_ENABLED" != "true" ]; then
    echo "SSL is not enabled. Skipping renewal."
    exit 0
fi

echo "Renewing SSL certificates..."

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
    docker exec xquantify-tradestation-nginx nginx -s reload
    echo "SSL certificates renewed and nginx reloaded!"
else
    echo "SSL certificates renewed! Restart nginx to apply changes."
fi
RENEWAL_SCRIPT

chmod +x scripts/renew-ssl.sh
print_success "Renewal script created at scripts/renew-ssl.sh"

# Create cron job for automatic renewal
print_info "Setting up automatic renewal..."
CRON_JOB="0 0 * * 0 cd $(pwd) && ./scripts/renew-ssl.sh >> logs/ssl-renewal.log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "renew-ssl.sh"; then
    print_warning "Cron job for SSL renewal already exists."
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    print_success "Automatic renewal scheduled (weekly check at midnight Sunday)"
fi

# Restart nginx if it was running
if [ "$RESTART_NGINX" = true ]; then
    print_info "Starting nginx with SSL enabled..."
    docker start xquantify-tradestation-nginx
    sleep 2
fi

# Final summary
echo ""
print_success "Let's Encrypt SSL setup complete!"
echo ""
print_info "Certificate details:"
echo "  Domain: $DOMAIN"
echo "  Email: $EMAIL"
echo "  Certificate: nginx/ssl/cert.pem"
echo "  Private Key: nginx/ssl/privkey.pem"
echo "  Expires: 90 days (auto-renewal configured)"
echo ""
print_info "Access your site at:"
echo -e "  ${GREEN}https://$DOMAIN:8443${NC}"
echo ""
print_info "Certificate auto-renewal:"
echo "  Schedule: Weekly check (Sundays at midnight)"
echo "  Manual renewal: ./scripts/renew-ssl.sh"
echo ""
print_warning "Important: Ensure port 443 (HTTPS) is open in your firewall!"
print_info "To open port 443:"
echo "  $SUDO ufw allow 443/tcp"
echo ""
print_success "Setup complete!"
