#!/bin/bash
#
# verify-installation.sh - Post-installation verification script
#
# This script checks if XQuantify TradeStation is properly installed and running
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo -e "${BLUE}"
    cat << "EOF"
╔════════════════════════════════════════════════╗
║   XQuantify TradeStation - Installation       ║
║           Verification Tool                   ║
╚════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}═══ $1 ═══${NC}"
    echo ""
}

# Check if running in project directory
check_directory() {
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Not in XQuantify TradeStation directory"
        print_info "Please run this script from the project root directory"
        exit 1
    fi
}

# Check Docker installation
check_docker() {
    print_section "Docker Environment"

    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker installed: $DOCKER_VERSION"
    else
        print_error "Docker not installed"
        return
    fi

    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        return
    fi

    # Check Docker Compose
    if docker compose version &> /dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version)
        print_success "Docker Compose installed: $COMPOSE_VERSION"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose version --short)
        print_success "Docker Compose installed: $COMPOSE_VERSION"
    else
        print_error "Docker Compose not installed"
    fi
}

# Check configuration files
check_config() {
    print_section "Configuration Files"

    # Check .env file
    if [ -f ".env" ]; then
        print_success ".env file exists"

        # Check important variables
        if grep -q "^VNC_PASSWORD=" .env; then
            print_success "VNC_PASSWORD configured"
        else
            print_warning "VNC_PASSWORD not set in .env"
        fi

        if grep -q "^BROKER=" .env; then
            BROKER=$(grep "^BROKER=" .env | cut -d= -f2)
            print_success "BROKER configured: $BROKER"
        else
            print_warning "BROKER not set in .env"
        fi
    else
        print_error ".env file missing"
        print_info "Run ./install.sh to create configuration"
    fi

    # Check gitattributes
    if [ -f ".gitattributes" ]; then
        print_success ".gitattributes exists (line ending enforcement)"
    else
        print_warning ".gitattributes missing"
    fi

    # Check editorconfig
    if [ -f ".editorconfig" ]; then
        print_success ".editorconfig exists"
    else
        print_warning ".editorconfig missing"
    fi
}

# Check required directories
check_directories() {
    print_section "Directory Structure"

    local dirs=("data" "logs" "backups" "nginx/ssl" "configs")

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_success "Directory exists: $dir"
        else
            print_warning "Directory missing: $dir"
            print_info "Creating $dir..."
            mkdir -p "$dir"
        fi
    done
}

# Check SSL certificates
check_ssl() {
    print_section "SSL Certificates"

    if [ -f "nginx/ssl/cert.pem" ] && [ -f "nginx/ssl/privkey.pem" ]; then
        print_success "SSL certificates found"

        # Check certificate validity
        if openssl x509 -checkend 86400 -noout -in nginx/ssl/cert.pem &> /dev/null; then
            print_success "SSL certificate is valid"

            # Show expiry date
            EXPIRY=$(openssl x509 -enddate -noout -in nginx/ssl/cert.pem | cut -d= -f2)
            print_info "Certificate expires: $EXPIRY"
        else
            print_error "SSL certificate expired or invalid"
            print_info "Regenerate with: ./scripts/generate-ssl.sh"
        fi
    else
        print_warning "SSL certificates not found"
        print_info "Generate with: ./scripts/generate-ssl.sh"
        print_info "Or run: make ssl-self-signed"
    fi
}

# Check Docker containers
check_containers() {
    print_section "Docker Containers"

    # Check if any containers are running
    if docker compose ps &> /dev/null || docker-compose ps &> /dev/null; then

        # Check specific containers
        local containers=("xquantify-tradestation-main" "xquantify-tradestation-nginx")

        for container in "${containers[@]}"; do
            if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
                STATUS=$(docker inspect --format='{{.State.Status}}' "$container")
                if [ "$STATUS" = "running" ]; then
                    print_success "Container running: $container"
                else
                    print_error "Container not running: $container (Status: $STATUS)"
                fi
            else
                print_warning "Container not found: $container"
            fi
        done
    else
        print_warning "No containers running"
        print_info "Start with: docker compose up -d"
    fi
}

# Check network connectivity
check_network() {
    print_section "Network Connectivity"

    # Get server IP
    PUBLIC_IP=$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null || echo "")
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

    if [ -n "$PUBLIC_IP" ]; then
        print_success "Public IP: $PUBLIC_IP"
    fi
    print_success "Local IP: $LOCAL_IP"

    # Check ports
    local ports=("6080" "8080" "8443" "5901")

    for port in "${ports[@]}"; do
        if nc -z localhost "$port" 2>/dev/null || timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/$port" 2>/dev/null; then
            print_success "Port $port is accessible"
        else
            print_warning "Port $port is not accessible"
        fi
    done
}

# Check HTTP/HTTPS endpoints
check_endpoints() {
    print_section "HTTP/HTTPS Endpoints"

    # Check HTTP
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null | grep -q "200"; then
        print_success "HTTP endpoint accessible (port 8080)"
    else
        print_warning "HTTP endpoint not accessible"
    fi

    # Check HTTPS
    if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/health 2>/dev/null | grep -q "200"; then
        print_success "HTTPS endpoint accessible (port 8443)"
    else
        print_warning "HTTPS endpoint not accessible"
    fi

    # Check direct MT5 access
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:6080/ 2>/dev/null | grep -q "200"; then
        print_success "Direct MT5 access available (port 6080)"
    else
        print_warning "Direct MT5 access not available"
    fi
}

# Check line endings
check_line_endings() {
    print_section "Line Endings"

    local has_crlf=false

    # Check shell scripts
    for script in scripts/*.sh install.sh start.sh uninstall.sh; do
        if [ -f "$script" ]; then
            if file "$script" | grep -q "CRLF"; then
                print_error "CRLF line endings detected: $script"
                has_crlf=true
            fi
        fi
    done

    if [ "$has_crlf" = false ]; then
        print_success "All scripts have correct line endings (LF)"
    else
        print_error "Some scripts have incorrect line endings"
        print_info "Fix with: make fix-line-endings"
        print_info "Or: ./scripts/fix-line-endings.sh"
    fi
}

# Check script permissions
check_permissions() {
    print_section "Script Permissions"

    local scripts=("install.sh" "uninstall.sh" "start.sh" "scripts/*.sh")

    for pattern in "${scripts[@]}"; do
        for script in $pattern; do
            if [ -f "$script" ]; then
                if [ -x "$script" ]; then
                    print_success "Executable: $script"
                else
                    print_warning "Not executable: $script"
                    print_info "Fix with: chmod +x $script"
                fi
            fi
        done
    done
}

# Provide access instructions
provide_access_info() {
    print_section "Access Information"

    # Get server IP
    PUBLIC_IP=$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null || echo "")
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

    SERVER_IP=${PUBLIC_IP:-$LOCAL_IP}

    echo -e "${GREEN}Access your MT5 platform:${NC}"
    echo ""
    echo -e "  ${GREEN}✓ HTTPS (Recommended):${NC}"
    echo -e "    https://${SERVER_IP}:8443/vnc.html"
    echo ""
    echo -e "  ${YELLOW}HTTP:${NC}"
    echo -e "    http://${SERVER_IP}:8080/vnc.html"
    echo ""
    echo -e "  ${YELLOW}Direct:${NC}"
    echo -e "    http://${SERVER_IP}:6080/vnc.html"
    echo ""

    if [ -f ".env" ]; then
        VNC_PASS=$(grep "^VNC_PASSWORD=" .env 2>/dev/null | cut -d= -f2 || echo "mt5password")
        echo -e "${BLUE}VNC Password:${NC} $VNC_PASS"
    fi
}

# Generate report
generate_report() {
    print_section "Verification Summary"

    local total=$((PASSED + FAILED + WARNINGS))

    echo -e "${GREEN}Passed:${NC}   $PASSED"
    echo -e "${RED}Failed:${NC}   $FAILED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "Total:    $total"
    echo ""

    if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        print_success "Installation is perfect! ✨"
        return 0
    elif [ $FAILED -eq 0 ]; then
        print_warning "Installation is working but has some warnings"
        return 0
    else
        print_error "Installation has some issues that need attention"
        echo ""
        print_info "Common fixes:"
        echo "  - Install dependencies: apt install docker.io docker-compose openssl curl"
        echo "  - Start services: docker compose up -d"
        echo "  - Generate SSL: ./scripts/generate-ssl.sh"
        echo "  - Fix line endings: ./scripts/fix-line-endings.sh"
        return 1
    fi
}

# Main verification flow
main() {
    print_header

    check_directory
    check_docker
    check_config
    check_directories
    check_ssl
    check_line_endings
    check_permissions
    check_containers
    check_network
    check_endpoints
    provide_access_info
    generate_report
}

# Run main function
main
