#!/bin/bash

# XQuantify TradeStation - SSL Certificate Generator
# Generates self-signed SSL certificates for HTTPS access

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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════╗
║   XQuantify TradeStation SSL Certificate Gen  ║
╚════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Create SSL directory
print_info "Creating SSL directory..."
mkdir -p nginx/ssl
cd nginx/ssl

# Get server IP or domain
print_info "Detecting server information..."
PUBLIC_IP=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || echo "")
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

echo ""
print_info "Detected IPs:"
echo "  Public IP: ${PUBLIC_IP:-Not detected}"
echo "  Local IP: ${LOCAL_IP}"
echo ""

read -p "Enter domain name or IP address for certificate [default: ${PUBLIC_IP:-$LOCAL_IP}]: " CERT_HOST
CERT_HOST=${CERT_HOST:-${PUBLIC_IP:-$LOCAL_IP}}

read -p "Enter organization name [default: XQuantify TradeStation]: " ORG_NAME
ORG_NAME=${ORG_NAME:-XQuantify TradeStation}

read -p "Certificate validity in days [default: 365]: " CERT_DAYS
CERT_DAYS=${CERT_DAYS:-365}

print_info "Generating self-signed SSL certificate..."

# Generate private key
openssl genrsa -out privkey.pem 4096 2>/dev/null

# Generate certificate
openssl req -new -x509 -key privkey.pem -out cert.pem -days $CERT_DAYS \
    -subj "/C=US/ST=State/L=City/O=${ORG_NAME}/CN=${CERT_HOST}" \
    -addext "subjectAltName=DNS:${CERT_HOST},DNS:localhost,IP:${PUBLIC_IP},IP:${LOCAL_IP},IP:127.0.0.1" \
    2>/dev/null

# Set proper permissions
chmod 644 cert.pem
chmod 600 privkey.pem

cd ../..

print_success "SSL certificates generated!"
echo ""
print_info "Certificate details:"
echo "  Location: nginx/ssl/"
echo "  Certificate: cert.pem"
echo "  Private Key: privkey.pem"
echo "  Valid for: ${CERT_DAYS} days"
echo "  Domain/IP: ${CERT_HOST}"
echo ""
print_warning "Note: This is a self-signed certificate."
print_info "Your browser will show a security warning. This is normal."
print_info "Click 'Advanced' -> 'Proceed to site' to access."
echo ""
print_info "To enable SSL, update your .env file:"
echo "  SSL_ENABLED=true"
echo ""
print_info "Then restart services:"
echo "  docker compose restart"
echo ""
print_success "Setup complete!"
