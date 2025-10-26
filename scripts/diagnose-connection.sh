#!/bin/bash
#
# diagnose-connection.sh - Diagnose MT5 VNC connection issues
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    echo ""
    echo -e "${BLUE}═══ $1 ═══${NC}"
    echo ""
}

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════╗
║   XQuantify TradeStation                       ║
║   Connection Diagnostic Tool                   ║
╚════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get server IP
PUBLIC_IP=$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null || echo "")
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
SERVER_IP=${PUBLIC_IP:-$LOCAL_IP}

print_section "Docker Container Status"

# Check MT5 main container
if docker ps --format "{{.Names}}" | grep -q "xquantify-tradestation-main"; then
    print_success "MT5 container is running"

    # Check container health
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' xquantify-tradestation-main 2>/dev/null || echo "no health check")
    if [ "$HEALTH" = "healthy" ]; then
        print_success "Container health: $HEALTH"
    else
        print_warning "Container health: $HEALTH"
    fi
else
    print_error "MT5 container is not running"
    print_info "Start with: docker compose up -d"
    exit 1
fi

# Check nginx container
if docker ps --format "{{.Names}}" | grep -q "xquantify-tradestation-nginx"; then
    print_success "Nginx container is running"
else
    print_error "Nginx container is not running"
fi

print_section "VNC Process Check"

# Check if VNC is running inside container
print_info "Checking VNC processes inside MT5 container..."
docker exec xquantify-tradestation-main ps aux | grep -E "vnc|x11|Xvfb" | grep -v grep || print_warning "No VNC processes found"

print_section "Port Connectivity"

# Check if port 6080 is accessible from nginx
print_info "Testing direct connection to MT5 noVNC (port 6080)..."
if docker exec xquantify-tradestation-nginx curl -s -o /dev/null -w "%{http_code}" http://xquantify-tradestation-main:6080/ 2>/dev/null | grep -q "200"; then
    print_success "Port 6080 is accessible from nginx"
else
    print_error "Port 6080 is NOT accessible from nginx"
    print_info "This indicates the VNC server is not responding"
fi

# Check VNC port 5901
print_info "Testing VNC port 5901..."
if docker exec xquantify-tradestation-main nc -z localhost 5901 2>/dev/null; then
    print_success "VNC port 5901 is listening"
else
    print_warning "VNC port 5901 is not accessible"
fi

print_section "SSL Certificate Check"

if [ -f "nginx/ssl/cert.pem" ]; then
    print_success "SSL certificate exists"

    # Check certificate details
    print_info "Certificate details:"
    openssl x509 -in nginx/ssl/cert.pem -noout -subject -issuer -dates 2>/dev/null || print_error "Failed to read certificate"

    # Check if expired
    if openssl x509 -checkend 0 -noout -in nginx/ssl/cert.pem 2>/dev/null; then
        print_success "Certificate is valid (not expired)"
    else
        print_error "Certificate has expired!"
        print_info "Regenerate with: ./scripts/generate-ssl.sh"
    fi
else
    print_error "SSL certificate not found"
    print_info "Generate with: ./scripts/generate-ssl.sh"
fi

print_section "Nginx Configuration"

print_info "Checking nginx WebSocket configuration..."
docker exec xquantify-tradestation-nginx cat /etc/nginx/nginx.conf | grep -A 5 "websockify" || print_warning "WebSocket proxy not configured"

print_section "Container Logs (Last 20 lines)"

print_info "MT5 Container Logs:"
docker logs --tail 20 xquantify-tradestation-main 2>&1 | tail -10

echo ""
print_info "Nginx Container Logs:"
docker logs --tail 20 xquantify-tradestation-nginx 2>&1 | tail -10

print_section "Connection Test Results"

# Test HTTP endpoint
print_info "Testing HTTP endpoint (port 8080)..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200"; then
    print_success "HTTP (port 8080) is working"
else
    print_warning "HTTP endpoint not responding"
fi

# Test HTTPS endpoint
print_info "Testing HTTPS endpoint (port 8443)..."
if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/ 2>/dev/null | grep -q "200"; then
    print_success "HTTPS (port 8443) is working"
else
    print_warning "HTTPS endpoint not responding"
fi

# Test direct noVNC
print_info "Testing direct noVNC access (port 6080)..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:6080/ 2>/dev/null | grep -q "200"; then
    print_success "Direct noVNC (port 6080) is working"
else
    print_error "Direct noVNC is not responding"
    print_info "VNC server may not be running properly"
fi

print_section "Recommended Actions"

echo ""
print_info "Based on the diagnostics:"
echo ""
echo "1. Browser Certificate Warning:"
echo "   - In Chrome: Click 'Advanced' → 'Proceed to ${SERVER_IP} (unsafe)'"
echo "   - In Firefox: Click 'Advanced' → 'Accept the Risk and Continue'"
echo "   - This is NORMAL for self-signed certificates"
echo ""
echo "2. If VNC is not responding:"
echo "   - Restart containers: docker compose restart"
echo "   - Check logs: docker compose logs -f xquantify-tradestation-main"
echo ""
echo "3. Test direct access (bypass SSL):"
echo "   http://${SERVER_IP}:6080/vnc.html"
echo ""
echo "4. Access URLs:"
echo "   HTTPS: https://${SERVER_IP}:8443/vnc.html"
echo "   HTTP:  http://${SERVER_IP}:8080/vnc.html"
echo "   Direct: http://${SERVER_IP}:6080/vnc.html"
echo ""

print_success "Diagnostic complete!"
