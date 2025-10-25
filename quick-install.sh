#!/bin/bash
#
# quick-install.sh - One-line installer for XQuantify TradeStation
#
# Usage: curl -fsSL https://raw.githubusercontent.com/yourusername/XQuantify-TradeStation/main/quick-install.sh | bash
# Or: wget -qO- https://raw.githubusercontent.com/yourusername/XQuantify-TradeStation/main/quick-install.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     XQuantify TradeStation - Quick Installer             ║
║     Professional MT5 Docker Platform                     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    echo "Install git first: sudo apt install git"
    exit 1
fi

# Clone or update repository
REPO_DIR="XQuantify-TradeStation"
REPO_URL="https://github.com/yourusername/XQuantify-TradeStation.git"

if [ -d "$REPO_DIR" ]; then
    echo -e "${BLUE}Repository exists, updating...${NC}"
    cd "$REPO_DIR"
    git pull
else
    echo -e "${BLUE}Cloning repository...${NC}"
    git clone "$REPO_URL"
    cd "$REPO_DIR"
fi

# Make scripts executable
chmod +x install.sh scripts/*.sh

# Run installer
echo -e "${GREEN}Starting installation wizard...${NC}"
./install.sh
