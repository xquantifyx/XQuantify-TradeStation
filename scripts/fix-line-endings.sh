#!/bin/bash
#
# fix-line-endings.sh - Convert all text files to LF line endings
#
# This script converts CRLF (Windows) line endings to LF (Unix) line endings
# for all text files in the repository. This ensures compatibility with Docker
# and Linux containers.
#
# Usage: ./scripts/fix-line-endings.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

cd "$PROJECT_DIR"

print_status "Starting line ending conversion..."
print_status "Working directory: $PROJECT_DIR"

# Counter for converted files
converted_count=0

# Function to convert a file to LF line endings
convert_file() {
    local file="$1"
    local basename=$(basename "$file")

    # Skip binary files and certain extensions
    case "$basename" in
        *.png|*.jpg|*.jpeg|*.gif|*.ico|*.zip|*.tar|*.gz|*.exe|*.dll|*.so)
            return
            ;;
    esac

    # Check if file has CRLF line endings
    if file "$file" | grep -q "CRLF"; then
        print_status "Converting: $file"

        # Create backup
        cp "$file" "$file.bak"

        # Convert CRLF to LF
        if command -v dos2unix &> /dev/null; then
            dos2unix "$file" 2>/dev/null
        else
            # Fallback: use sed if dos2unix is not available
            sed -i 's/\r$//' "$file" 2>/dev/null || sed -i '' 's/\r$//' "$file" 2>/dev/null
        fi

        # Remove backup if conversion was successful
        if [ $? -eq 0 ]; then
            rm "$file.bak"
            ((converted_count++))
            print_success "Converted: $file"
        else
            # Restore from backup if conversion failed
            mv "$file.bak" "$file"
            print_error "Failed to convert: $file"
        fi
    fi
}

# Convert shell scripts
print_status "Converting shell scripts..."
find . -type f -name "*.sh" ! -path "*/node_modules/*" ! -path "*/.git/*" | while read file; do
    convert_file "$file"
done

# Convert Dockerfile
print_status "Converting Dockerfiles..."
find . -type f -name "Dockerfile*" ! -path "*/node_modules/*" ! -path "*/.git/*" | while read file; do
    convert_file "$file"
done

# Convert configuration files
print_status "Converting configuration files..."
find . -type f \( -name "*.conf" -o -name "*.yml" -o -name "*.yaml" \) ! -path "*/node_modules/*" ! -path "*/.git/*" | while read file; do
    convert_file "$file"
done

# Convert Makefile
print_status "Converting Makefile..."
if [ -f "Makefile" ]; then
    convert_file "Makefile"
fi

# Convert environment files
print_status "Converting environment files..."
find . -type f -name ".env*" ! -path "*/node_modules/*" ! -path "*/.git/*" | while read file; do
    convert_file "$file"
done

# Convert markdown and text files
print_status "Converting documentation files..."
find . -type f \( -name "*.md" -o -name "*.txt" \) ! -path "*/node_modules/*" ! -path "*/.git/*" | while read file; do
    convert_file "$file"
done

# Convert source code files
print_status "Converting source code files..."
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.json" -o -name "*.xml" -o -name "*.html" -o -name "*.css" \) ! -path "*/node_modules/*" ! -path "*/.git/*" | while read file; do
    convert_file "$file"
done

print_success "Line ending conversion complete!"
print_status "Total files converted: $converted_count"

# Make all shell scripts executable
print_status "Setting executable permissions on shell scripts..."
find . -type f -name "*.sh" ! -path "*/node_modules/*" ! -path "*/.git/*" -exec chmod +x {} \;

print_success "All shell scripts are now executable!"

# Verify conversion
print_status "Verifying conversion..."
has_crlf=false

find . -type f \( -name "*.sh" -o -name "Dockerfile*" -o -name "*.conf" -o -name "*.yml" -o -name "*.yaml" -o -name "Makefile" \) ! -path "*/node_modules/*" ! -path "*/.git/*" | while read file; do
    if file "$file" | grep -q "CRLF"; then
        print_warning "Still has CRLF: $file"
        has_crlf=true
    fi
done

if [ "$has_crlf" = false ]; then
    print_success "All files have correct line endings!"
else
    print_warning "Some files still have CRLF line endings. You may need to install dos2unix for better conversion."
fi

print_status "Done! Your repository is now configured with LF line endings."
print_status "The .gitattributes file will ensure new files use LF line endings."
