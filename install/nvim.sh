#!/bin/bash

# Neovim Latest Version Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/main/install-nvim.sh | bash
# Force install: curl -fsSL ... | bash -s -- --force

set -eu  # Removed pipefail temporarily

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log() { echo -e "${BLUE}[INFO] ${NC} $1"; }
success() { echo -e "${GREEN}[OK]   ${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN] ${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check for --force flag
FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

# Safety checks (commented out for testing)
# [[ $EUID -eq 0 ]] && error "Don't run as root. Script will sudo when needed."
command -v curl &>/dev/null || error "curl required: sudo apt install curl"

# Detect architecture
arch=$(uname -m)
case $arch in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $arch" ;;
esac

# Check glibc version for compatibility
USE_LEGACY=false
if command -v ldd &>/dev/null; then
    glibc_version=$(ldd --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
    log "Detected glibc version: $glibc_version"
    [[ $(echo "$glibc_version 2.34" | awk '{print ($1 < $2)}') == 1 ]] && USE_LEGACY=true
fi

# Force legacy for Ubuntu 20.04 specifically (usually has glibc < 2.34)
if grep -q "20.04" /etc/os-release 2>/dev/null; then
    log "Ubuntu 20.04 detected - using legacy version"
    USE_LEGACY=true
fi

# Get versions
log "Checking versions..."

# Current version
CURRENT_VERSION=""
if command -v nvim &>/dev/null; then
    CURRENT_VERSION=$(nvim --version 2>/dev/null | head -n1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
fi

# Latest version
if [[ "$USE_LEGACY" == true ]]; then
    LATEST_VERSION="v0.11.3"
    DOWNLOAD_URL="https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage"
    log "Using legacy version due to old glibc"
else
    log "Fetching latest version..."
    LATEST_VERSION=""

    # Method 1: Try direct redirect check (most reliable)
    log "Checking latest download redirect..."
    if REDIRECT_URL=$(timeout 10 curl -Ls -o /dev/null -w "%{url_effective}" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage" 2>/dev/null); then
        LATEST_VERSION=$(echo "$REDIRECT_URL" | grep -Po '/download/\Kv[0-9]+\.[0-9]+\.[0-9]+' || echo "")
        if [[ -n "$LATEST_VERSION" ]]; then
            DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage"
            log "Got version from redirect: $LATEST_VERSION"
        fi
    fi

    # Method 2: Try GitHub API if redirect failed
    if [[ -z "$LATEST_VERSION" ]]; then
        log "Redirect failed, trying GitHub API..."
        for attempt in 1 2; do
            if LATEST_VERSION=$(timeout 15 curl -sL \
                "https://api.github.com/repos/neovim/neovim/releases/latest" 2>/dev/null | \
                grep -Po '"tag_name": "\K[^"]*' 2>/dev/null); then
                DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage"
                log "Got version from API: $LATEST_VERSION"
                break
            fi
            [[ $attempt -lt 2 ]] && { log "API attempt $attempt failed, retrying..."; sleep 2; }
        done
    fi

    # Method 3: Last resort - use known stable version
    if [[ -z "$LATEST_VERSION" ]]; then
        log "Using direct latest download (version detection unavailable)"
        LATEST_VERSION="latest"
        DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage"
    fi
fi

# Show version info
if [[ -n "$CURRENT_VERSION" ]] && [[ "$CURRENT_VERSION" != "unknown" ]]; then
    log "Current version: $CURRENT_VERSION"
else
    log "Current version: not installed"
fi
log "Latest version:  $LATEST_VERSION"

# Version comparison
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]] && [[ "$FORCE" != true ]]; then
    success "Neovim $CURRENT_VERSION is already up to date!"
    log "To force reinstall, run with --force flag"
    exit 0
fi

# If versions differ and no force flag, download and test first
if [[ "$FORCE" != true ]] && [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]] && [[ -n "$CURRENT_VERSION" ]] && [[ "$CURRENT_VERSION" != "unknown" ]]; then
    log "Different versions detected - testing new version compatibility..."

    # Create temp directory for testing
    TEMP_DIR=$(mktemp -d)
    log "Using temporary directory: $TEMP_DIR"
    cleanup() {
        log "Cleaning up temporary files..."
        [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
    }
    trap cleanup EXIT INT TERM

    # Download and test new version
    cd "$TEMP_DIR"
    log "Downloading Neovim $LATEST_VERSION for compatibility testing..."

    if [[ "$USE_LEGACY" == true ]]; then
        DOWNLOAD_URL="https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage"
    else
        DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage"
    fi

    if ! curl -fsSL -o "nvim.appimage" "$DOWNLOAD_URL"; then
        error "Failed to download new version for testing"
    fi

    # Test the new binary
    chmod +x nvim.appimage
    if ! timeout 10 ./nvim.appimage --version >/dev/null 2>&1; then
        error "New version binary test failed - upgrade not recommended"
    fi

    success "New version tested successfully"
    echo
    log "Ready to upgrade from $CURRENT_VERSION to $LATEST_VERSION"
    error "Rerun with --force to proceed with upgrade:
    curl -fsSL https://your-url/install-nvim.sh | bash -s -- --force"
fi

# Proceeding with installation
if [[ "$FORCE" == true ]]; then
    log "Force flag detected - proceeding with installation"
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
log "Using temporary directory: $TEMP_DIR"
cleanup() {
    log "Cleaning up temporary files..."
    [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT INT TERM

# Download and install
log "Downloading Neovim $LATEST_VERSION for $ARCH..."
log "Download URL: $DOWNLOAD_URL"
cd "$TEMP_DIR"

if ! curl -fsSL -o "nvim.appimage" "$DOWNLOAD_URL"; then
    [[ "$USE_LEGACY" == false ]] && {
        log "Trying legacy version..."
        USE_LEGACY=true
        LATEST_VERSION="v0.11.3"
        DOWNLOAD_URL="https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage"
        curl -fsSL -o "nvim.appimage" "$DOWNLOAD_URL" || error "Download failed"
    }
fi

# Verify checksum if available
log "Verifying download integrity..."
CHECKSUM_URL=""
if [[ "$USE_LEGACY" == true ]]; then
    CHECKSUM_URL="https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage.sha256sum"
else
    CHECKSUM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage.sha256sum"
fi

if curl -fsSL "$CHECKSUM_URL" -o "nvim.appimage.sha256sum" 2>/dev/null; then
    if command -v sha256sum &>/dev/null; then
        if sha256sum -c "nvim.appimage.sha256sum" >/dev/null 2>&1; then
            success "Checksum verification passed"
        else
            error "Checksum verification failed - download may be corrupted"
        fi
    else
        log "sha256sum not available, skipping checksum verification"
    fi
else
    warn "Checksum file not available, skipping verification"
fi

# Test binary
log "Testing downloaded binary..."
chmod +x nvim.appimage

# Debug: Check file info
log "Binary size: $(stat -c%s nvim.appimage) bytes"
log "Binary type: $(file nvim.appimage)"

if ! timeout 10 ./nvim.appimage --version >/dev/null 2>&1; then
    log "Detailed error output:"
    timeout 10 ./nvim.appimage --version 2>&1 || true
    error "Downloaded binary test failed - binary may be corrupted"
fi

# Test that it can actually start (more thorough test)
if ! timeout 5 ./nvim.appimage --headless -c "echo 'test'" -c "qa!" >/dev/null 2>&1; then
    log "Headless start failed, but basic version test passed - continuing"
    log "This may be due to missing dependencies for full startup"
else
    success "Full binary tests passed"
fi

# Backup and install
[[ -f "/usr/local/bin/nvim" ]] && sudo cp /usr/local/bin/nvim "/usr/local/bin/nvim.backup.$(date +%s)"

log "Installing to /usr/local/bin/nvim..."
sudo cp nvim.appimage /usr/local/bin/nvim
sudo chmod +x /usr/local/bin/nvim

# Verify
nvim --version >/dev/null || error "Installation verification failed"
success "Neovim $LATEST_VERSION installed successfully!"
log "Run 'nvim --version' to verify"
