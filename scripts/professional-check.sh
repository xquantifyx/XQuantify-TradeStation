#!/bin/bash
#
# professional-check.sh - Comprehensive project validation
#
# This script performs a complete professional check of the entire project
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

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

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════╗
║   XQuantify TradeStation                       ║
║   Professional Quality Check                   ║
╚════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 1. Check Shell Script Syntax
print_section "Shell Script Syntax Validation"

for script in install.sh uninstall.sh start.sh scripts/*.sh; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            print_success "Syntax valid: $script"
        else
            print_error "Syntax error: $script"
        fi
    fi
done

# 2. Check Line Endings
print_section "Line Ending Check (Must be LF)"

has_crlf=false
for file in install.sh uninstall.sh start.sh scripts/*.sh; do
    if [ -f "$file" ]; then
        if file "$file" | grep -q "CRLF"; then
            print_error "CRLF detected: $file"
            has_crlf=true
        else
            print_success "LF correct: $file"
        fi
    fi
done

if [ "$has_crlf" = true ]; then
    print_warning "Run: ./scripts/fix-line-endings.sh to fix"
fi

# 3. Check File Permissions
print_section "File Permissions Check"

for script in install.sh uninstall.sh start.sh scripts/*.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_success "Executable: $script"
        else
            print_warning "Not executable: $script (run: chmod +x $script)"
        fi
    fi
done

# 4. Check Required Files
print_section "Required Files Check"

required_files=(
    "install.sh"
    "uninstall.sh"
    "start.sh"
    "docker-compose.yml"
    "Dockerfile"
    "Makefile"
    ".gitattributes"
    ".editorconfig"
    ".env.example"
    "README.md"
    "QUICKSTART.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found: $file"
    else
        print_error "Missing: $file"
    fi
done

# 5. Check Required Directories
print_section "Directory Structure Check"

required_dirs=(
    "scripts"
    "nginx"
    "configs"
    "data"
    "logs"
    "backups"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_success "Found: $dir/"
    else
        print_warning "Missing: $dir/ (will be created during install)"
    fi
done

# 6. Check Docker Configuration
print_section "Docker Configuration Validation"

if command -v docker &> /dev/null; then
    if docker compose -f docker-compose.yml config > /dev/null 2>&1; then
        print_success "docker-compose.yml is valid"
    else
        print_error "docker-compose.yml has errors"
    fi
else
    print_warning "Docker not installed - cannot validate docker-compose.yml"
fi

# 7. Check Documentation
print_section "Documentation Check"

docs=(
    "README.md"
    "QUICKSTART.md"
    "INSTALL.md"
    "CLAUDE.md"
    "QUICK-SSL-SETUP.md"
    "PORT-80-CONFLICT-FIX.md"
    "NGINX-COEXISTENCE.md"
    "NORMALIZE-LINE-ENDINGS.md"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        lines=$(wc -l < "$doc")
        if [ "$lines" -gt 10 ]; then
            print_success "$doc ($lines lines)"
        else
            print_warning "$doc is very short ($lines lines)"
        fi
    else
        print_error "Missing: $doc"
    fi
done

# 8. Check Script Functionality
print_section "Script Functionality Tests"

# Check if scripts have proper shebang
for script in install.sh uninstall.sh start.sh scripts/*.sh; do
    if [ -f "$script" ]; then
        first_line=$(head -n 1 "$script")
        if [[ "$first_line" == "#!/bin/bash"* ]] || [[ "$first_line" == "#!/usr/bin/env bash"* ]]; then
            print_success "Valid shebang: $script"
        else
            print_error "Invalid/missing shebang: $script"
        fi
    fi
done

# 9. Check for Common Issues
print_section "Common Issues Check"

# Check for hardcoded IPs/passwords (security)
if grep -r "password.*=" --include="*.sh" --include="*.yml" . 2>/dev/null | grep -v ".env" | grep -v "example" | grep -q "password"; then
    print_warning "Possible hardcoded passwords found - review manually"
else
    print_success "No obvious hardcoded passwords"
fi

# Check for proper error handling
if grep -q "set -e" install.sh && grep -q "set -e" uninstall.sh; then
    print_success "Scripts have error handling (set -e)"
else
    print_warning "Some scripts may lack error handling"
fi

# 10. Summary
print_section "Quality Check Summary"

total=$((PASSED + FAILED + WARNINGS))
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${RED}Failed:${NC}   $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "Total:    $total"
echo ""

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_success "Project is in excellent condition! ✨"
    echo ""
    print_info "Ready for production deployment"
    exit 0
elif [ $FAILED -eq 0 ]; then
    print_success "Project is in good condition"
    print_warning "Some minor warnings to address"
    echo ""
    exit 0
else
    print_error "Project has issues that need attention"
    echo ""
    print_info "Please fix the errors listed above"
    exit 1
fi
