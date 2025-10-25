# Line Ending Normalization Guide

This document explains how to permanently fix line ending issues in this repository.

## The Problem

If files are committed with Windows line endings (CRLF), they will cause errors on Linux:
```
-bash: ./install.sh: /bin/bash^M: bad interpreter: No such file or directory
```

## The Solution

This repository now uses **strict LF (Unix) line endings** for all files, enforced by:
1. **`.gitattributes`** - Git configuration for line endings
2. **`.editorconfig`** - Editor configuration for consistency

## One-Time Repository Normalization

### If You're the Repository Owner (Windows or Linux)

Run these commands ONCE to normalize all files in Git:

```bash
# Step 1: Ensure you have the latest .gitattributes and .editorconfig
git pull origin main

# Step 2: Remove all files from Git index (doesn't delete files)
git rm --cached -r .

# Step 3: Re-add all files with normalized line endings
git reset --hard HEAD
git add --renormalize .

# Step 4: Commit the normalized files
git commit -m "Normalize all files to LF line endings

- Updated .gitattributes to enforce LF for all text files
- Added .editorconfig for editor consistency
- Normalized all existing files to LF
- Fixes cross-platform compatibility issues"

# Step 5: Force push (ONLY if you're sure no one else is working on the repo)
git push origin main --force

# OR regular push (safer)
git push origin main
```

### If You Just Cloned on Linux (After Normalization)

If the repository has already been normalized, you should get correct line endings automatically. Verify:

```bash
# Check a shell script
file install.sh
# Should show: "Bourne-Again shell script, ASCII text executable"
# Should NOT show: "CRLF"

# If files still have CRLF, re-clone:
cd ..
rm -rf XQuantify-TradeStation
git clone https://github.com/yourusername/XQuantify-TradeStation.git
cd XQuantify-TradeStation
```

## How It Works Now

### `.gitattributes` Configuration

All text files are configured with `eol=lf`, which means:

- **In the repository:** Always stored with LF
- **In your working directory:** Always checked out with LF
- **On Windows:** Files will have LF (not CRLF)
- **On Linux/Mac:** Files will have LF

This ensures **100% consistency** across all platforms.

### `.editorconfig` Configuration

Supported editors (VS Code, Sublime, IntelliJ, Vim, etc.) will automatically:
- Use LF line endings when creating new files
- Maintain LF line endings when editing existing files
- Use correct indentation (spaces vs tabs)

## For Windows Developers

### Configure Git Globally

Set Git to NOT convert line endings automatically:

```bash
# Don't convert LF to CRLF on checkout
git config --global core.autocrlf false

# Warn on commit if CRLF is detected
git config --global core.safecrlf warn
```

### Configure Your Editor

#### Visual Studio Code
Install the EditorConfig extension (if not already installed), then:
```json
// settings.json
{
  "files.eol": "\n",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true
}
```

#### Notepad++
Settings → Preferences → New Document → Format (Line ending): Unix (LF)

#### Sublime Text
```json
// Preferences.sublime-settings
{
  "default_line_ending": "unix"
}
```

## Verifying Line Endings

### On Linux/Mac
```bash
file *.sh
# Should show: "ASCII text" or "ASCII text executable"
# Should NOT show: "CRLF"
```

### On Windows (Git Bash)
```bash
dos2unix --info *.sh
# Or check with:
git ls-files --eol
```

### Using Git
```bash
# Check line endings of all files
git ls-files --eol

# Output format:
# i/lf    w/lf    attr/text eol=lf    install.sh
#  ^       ^       ^
#  |       |       |
#  |       |       +-- .gitattributes setting
#  |       +-- Working directory (what you see)
#  +-- Index/Repository (what's stored in Git)
```

All files should show `i/lf w/lf` for proper LF line endings.

## Troubleshooting

### Problem: Files still have CRLF after cloning

**Solution:**
```bash
# Re-clone the repository
cd ..
rm -rf XQuantify-TradeStation
git clone https://github.com/yourusername/XQuantify-TradeStation.git
```

### Problem: Editor keeps converting to CRLF

**Solution:**
1. Install EditorConfig extension for your editor
2. Configure editor settings (see above)
3. Close and reopen the file

### Problem: Git shows files as modified after normalization

**Solution:**
```bash
# This is normal after normalization. Commit the changes:
git add .
git commit -m "Normalize line endings"
git push
```

## Prevention

With `.gitattributes` and `.editorconfig` in place:

✅ **New files** will automatically use LF
✅ **Edited files** will maintain LF
✅ **Committed files** will always be stored as LF
✅ **No manual fixes needed** on any platform

## Testing

After normalization, test on Linux:

```bash
./install.sh
# Should work without errors!
```

## References

- [Git Documentation - gitattributes](https://git-scm.com/docs/gitattributes)
- [EditorConfig Documentation](https://editorconfig.org/)
- [GitHub - Line Ending Guide](https://docs.github.com/en/get-started/getting-started-with-git/configuring-git-to-handle-line-endings)
