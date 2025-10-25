#
# fix-line-endings.ps1 - Convert all text files to LF line endings (PowerShell)
#
# This script converts CRLF (Windows) line endings to LF (Unix) line endings
# for all text files in the repository. This ensures compatibility with Docker
# and Linux containers.
#
# Usage: .\scripts\fix-line-endings.ps1
#

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Get project directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Set-Location $ProjectDir

Write-Status "Starting line ending conversion..."
Write-Status "Working directory: $ProjectDir"

# Counter for converted files
$convertedCount = 0
$totalFiles = 0

# Binary file extensions to skip
$binaryExtensions = @('.png', '.jpg', '.jpeg', '.gif', '.ico', '.zip', '.tar', '.gz', '.exe', '.dll', '.so')

# Function to check if file is binary
function Test-BinaryFile {
    param([string]$FilePath)
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    return $binaryExtensions -contains $extension
}

# Function to check if file has CRLF line endings
function Test-CRLFLineEndings {
    param([string]$FilePath)

    try {
        $content = [System.IO.File]::ReadAllText($FilePath)
        return $content -match "`r`n"
    }
    catch {
        return $false
    }
}

# Function to convert a file to LF line endings
function Convert-ToLF {
    param([string]$FilePath)

    $totalFiles++

    # Skip binary files
    if (Test-BinaryFile $FilePath) {
        return
    }

    # Check if file has CRLF line endings
    if (Test-CRLFLineEndings $FilePath) {
        Write-Status "Converting: $FilePath"

        try {
            # Read file content
            $content = [System.IO.File]::ReadAllText($FilePath)

            # Convert CRLF to LF
            $content = $content -replace "`r`n", "`n"

            # Write back to file with UTF-8 encoding (no BOM)
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($FilePath, $content, $utf8NoBom)

            $script:convertedCount++
            Write-Success "Converted: $FilePath"
        }
        catch {
            Write-Error "Failed to convert: $FilePath - $_"
        }
    }
}

# Convert shell scripts
Write-Status "Converting shell scripts..."
Get-ChildItem -Path . -Filter "*.sh" -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\.git\\' } |
    ForEach-Object { Convert-ToLF $_.FullName }

# Convert Dockerfiles
Write-Status "Converting Dockerfiles..."
Get-ChildItem -Path . -Filter "Dockerfile*" -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\.git\\' } |
    ForEach-Object { Convert-ToLF $_.FullName }

# Convert configuration files
Write-Status "Converting configuration files..."
Get-ChildItem -Path . -Include "*.conf", "*.yml", "*.yaml" -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\.git\\' } |
    ForEach-Object { Convert-ToLF $_.FullName }

# Convert Makefile
Write-Status "Converting Makefile..."
if (Test-Path "Makefile") {
    Convert-ToLF (Join-Path $ProjectDir "Makefile")
}

# Convert environment files
Write-Status "Converting environment files..."
Get-ChildItem -Path . -Filter ".env*" -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\.git\\' } |
    ForEach-Object { Convert-ToLF $_.FullName }

# Convert markdown and text files
Write-Status "Converting documentation files..."
Get-ChildItem -Path . -Include "*.md", "*.txt" -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\.git\\' } |
    ForEach-Object { Convert-ToLF $_.FullName }

# Convert source code files
Write-Status "Converting source code files..."
Get-ChildItem -Path . -Include "*.py", "*.js", "*.json", "*.xml", "*.html", "*.css" -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\.git\\' } |
    ForEach-Object { Convert-ToLF $_.FullName }

Write-Success "Line ending conversion complete!"
Write-Status "Total files processed: $totalFiles"
Write-Status "Files converted: $convertedCount"

# Verify conversion
Write-Status "Verifying conversion..."
$hasCRLF = $false

$filesToVerify = @(
    (Get-ChildItem -Path . -Filter "*.sh" -Recurse -File),
    (Get-ChildItem -Path . -Filter "Dockerfile*" -Recurse -File),
    (Get-ChildItem -Path . -Include "*.conf", "*.yml", "*.yaml" -Recurse -File),
    (Get-Item "Makefile" -ErrorAction SilentlyContinue)
) | Where-Object {
    $_ -and $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\.git\\'
}

foreach ($file in $filesToVerify) {
    if ($file -and (Test-CRLFLineEndings $file.FullName)) {
        Write-Warning "Still has CRLF: $($file.FullName)"
        $hasCRLF = $true
    }
}

if (-not $hasCRLF) {
    Write-Success "All critical files have correct line endings!"
}
else {
    Write-Warning "Some files still have CRLF line endings. They may need manual conversion."
}

Write-Status "Done! Your repository is now configured with LF line endings."
Write-Status "The .gitattributes file will ensure new files use LF line endings."

# Instructions for Git
Write-Status ""
Write-Status "Next steps:"
Write-Status "1. Run: git add --renormalize ."
Write-Status "2. Run: git status (to see which files will be updated)"
Write-Status "3. Run: git commit -m 'Fix line endings to LF'"
Write-Status ""
Write-Success "Line ending fix complete!"
