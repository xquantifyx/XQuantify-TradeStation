#!/bin/bash
#
# fix-port-conflict.sh - Diagnose and fix port 80/443 conflicts
#
# This script helps identify what's using ports 80 and 443 and provides
# solutions for SSL certificate setup.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    cat << "EOF"
╔════════════════════════════════════════════════╗
║     XQuantify TradeStation - Port Conflict    ║
║              Diagnostic Tool                  ║
╚════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_header

print_info "Checking ports 80 and 443..."
echo ""

# Check port 80
echo -e "${BLUE}Port 80 Status:${NC}"
PORT80=$(sudo netstat -tlnp 2>/dev/null | grep ":80 " || sudo ss -tlnp 2>/dev/null | grep ":80 " || echo "")
if [ -z "$PORT80" ]; then
    print_success "Port 80 is available"
    PORT80_FREE=true
else
    print_warning "Port 80 is in use:"
    echo "$PORT80"
    PORT80_FREE=false

    # Try to identify the process
    PORT80_PID=$(echo "$PORT80" | grep -oP '(?<=pid=)\d+' | head -1 || echo "")
    if [ -z "$PORT80_PID" ]; then
        PORT80_PID=$(sudo lsof -ti:80 2>/dev/null || echo "")
    fi

    if [ -n "$PORT80_PID" ]; then
        print_info "Process using port 80: PID $PORT80_PID"
        ps -p "$PORT80_PID" -o comm= 2>/dev/null || echo "Unknown process"
    fi
fi
echo ""

# Check port 443
echo -e "${BLUE}Port 443 Status:${NC}"
PORT443=$(sudo netstat -tlnp 2>/dev/null | grep ":443 " || sudo ss -tlnp 2>/dev/null | grep ":443 " || echo "")
if [ -z "$PORT443" ]; then
    print_success "Port 443 is available"
    PORT443_FREE=true
else
    print_warning "Port 443 is in use:"
    echo "$PORT443"
    PORT443_FREE=false
fi
echo ""

# Check for common services
print_info "Checking for common services..."
echo ""

# Apache
if systemctl is-active --quiet apache2 2>/dev/null || systemctl is-active --quiet httpd 2>/dev/null; then
    print_warning "Apache web server is running"
    echo "  To stop: sudo systemctl stop apache2 (or httpd)"
    echo "  To disable: sudo systemctl disable apache2"
    APACHE_RUNNING=true
else
    APACHE_RUNNING=false
fi

# Nginx (system)
if systemctl is-active --quiet nginx 2>/dev/null; then
    print_warning "System nginx is running"
    echo "  To stop: sudo systemctl stop nginx"
    echo "  To disable: sudo systemctl disable nginx"
    NGINX_RUNNING=true
else
    NGINX_RUNNING=false
fi

# Docker containers using port 80
print_info "Checking Docker containers using port 80..."
DOCKER_PORT80=$(docker ps --format "{{.Names}}: {{.Ports}}" 2>/dev/null | grep "0.0.0.0:80->" || echo "")
if [ -n "$DOCKER_PORT80" ]; then
    print_warning "Docker containers using port 80:"
    echo "$DOCKER_PORT80"
fi
echo ""

# Provide solutions
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}              SOLUTION OPTIONS                ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

if [ "$PORT80_FREE" = false ] || [ "$PORT443_FREE" = false ]; then
    echo -e "${YELLOW}Option 1: Use Self-Signed Certificate (Recommended - No port 80 needed)${NC}"
    echo "This bypasses the port 80 requirement and works immediately:"
    echo ""
    echo "  ./scripts/generate-ssl.sh"
    echo ""
    echo "Browser will show a security warning (this is normal for self-signed certs)."
    echo "Access via: https://$(curl -s ifconfig.me):8443/vnc.html"
    echo ""

    echo -e "${YELLOW}Option 2: Use Alternative Ports${NC}"
    echo "Configure XQuantify to use non-standard ports:"
    echo ""
    echo "  Edit docker-compose.yml:"
    echo "    nginx:"
    echo "      ports:"
    echo "        - \"8080:80\"   # HTTP on port 8080"
    echo "        - \"8443:443\"  # HTTPS on port 8443"
    echo ""
    echo "Access via: https://$(curl -s ifconfig.me):8443/vnc.html"
    echo ""

    if [ "$APACHE_RUNNING" = true ] || [ "$NGINX_RUNNING" = true ]; then
        echo -e "${YELLOW}Option 3: Stop Conflicting Service${NC}"

        if [ "$APACHE_RUNNING" = true ]; then
            echo "Stop Apache:"
            echo "  sudo systemctl stop apache2"
            echo "  sudo systemctl disable apache2"
            echo ""
        fi

        if [ "$NGINX_RUNNING" = true ]; then
            echo "Stop system nginx:"
            echo "  sudo systemctl stop nginx"
            echo "  sudo systemctl disable nginx"
            echo ""
        fi

        echo "Then retry Let's Encrypt setup:"
        echo "  ./scripts/setup-letsencrypt.sh"
        echo ""
    fi

    echo -e "${YELLOW}Option 4: Use DNS Challenge (Advanced)${NC}"
    echo "If you can't free port 80, use DNS challenge for Let's Encrypt:"
    echo ""
    echo "  docker compose run --rm certbot certonly \\"
    echo "    --manual \\"
    echo "    --preferred-challenges dns \\"
    echo "    -d yourdomain.com"
    echo ""
else
    print_success "Ports 80 and 443 are available!"
    print_info "You can proceed with Let's Encrypt setup:"
    echo ""
    echo "  ./scripts/setup-letsencrypt.sh"
    echo ""
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
print_info "Quick command to use self-signed certificate (works immediately):"
echo ""
echo "  make ssl-self-signed"
echo ""
print_success "Diagnostic complete!"
