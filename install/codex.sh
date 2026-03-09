#!/usr/bin/env bash
# Version: v0.1.7
# Codex Installer (Resilient API version)

set -euo pipefail

# ---------- Colors & logging ----------
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()     { printf "${BLUE}[INFO] ${NC}%s\n"  "$*" >&2; }
success() { printf "${GREEN}[OK]   ${NC}%s\n" "$*" >&2; }
error()   { printf "${RED}[ERROR]${NC}%s\n"   "$*" >&2; exit 1; }

PREFIX="${HOME}/.local/bin"
mkdir -p "$PREFIX"

# ---------- 1. Architecture Detection ----------
arch=$(uname -m)
case "$arch" in
  x86_64)  ARCH_TYPE="x86_64" ;;
  aarch64|arm64) ARCH_TYPE="aarch64" ;;
  *) error "Unsupported architecture: $arch" ;;
esac

# ---------- 2. Ensure DotSlash is Installed ----------
if [[ ! -x "$PREFIX/dotslash" ]] && ! command -v dotslash >/dev/null 2>&1; then
  log "DotSlash not found. Installing..."
  DOTSLASH_URL="https://github.com/facebook/dotslash/releases/latest/download/dotslash-ubuntu-22.04.${arch}.tar.gz"
  curl -LSfs "$DOTSLASH_URL" | tar fxz - -C "$PREFIX"
  chmod +x "$PREFIX/dotslash"
fi

# ---------- 3. Resolve Latest Codex Tag (Improved) ----------
log "Checking GitHub for latest Codex release..."

# We use -w "%{url_effective}" to see where 'latest' actually points
LATEST_URL=$(curl -Ls -o /dev/null -w "%{url_effective}" https://github.com/openai/codex/releases/latest)
LATEST_TAG="${LATEST_URL##*/}"

if [[ -z "$LATEST_TAG" || "$LATEST_TAG" == "latest" ]]; then
  # Fallback to API if redirect fails
  LATEST_TAG=$(curl -s https://api.github.com/repos/openai/codex/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)
fi

[[ -z "$LATEST_TAG" ]] && error "Could not resolve latest Codex version."

# ---------- 4. Download Codex Manifest ----------
BINARY_URL="https://github.com/openai/codex/releases/download/${LATEST_TAG}/codex"

log "Downloading Codex $LATEST_TAG..."
# -f makes curl fail on 404 instead of saving the error page
if curl -fL -o "$PREFIX/codex" "$BINARY_URL"; then
  chmod +x "$PREFIX/codex"
else
  error "Download failed (404). The tag '$LATEST_TAG' might not have a binary named 'codex'."
fi

# ---------- 5. Verification ----------
export PATH="$PREFIX:$PATH"

log "Verifying installation..."
if "$PREFIX/codex" --version >/dev/null 2>&1; then
  success "Successfully installed $("$PREFIX/codex" --version)"
else
  error "Verification failed. Check if 'dotslash' is functional."
fi
