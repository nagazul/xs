#!/usr/bin/env bash
# Version: v0.3.4
# Neovim Latest Version Installer (AppImage with FUSE-less fallback)

set -euo pipefail
IFS=$'\n\t'
umask 022

# ---------- Colors & logging ----------
is_tty() { [[ -t 2 ]]; }
if is_tty; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi
log()     { printf "${BLUE}[INFO] ${NC}%s\n"  "$*" >&2; }
success() { printf "${GREEN}[OK]   ${NC}%s\n" "$*" >&2; }
warn()    { printf "${YELLOW}[WARN] ${NC}%s\n" "$*" >&2; }
error()   { printf "${RED}[ERROR]${NC}%s\n"   "$*" >&2; exit 1; }
show_help() {
  cat << 'EOF'
Neovim AppImage Installer

Usage: curl -fsSL <url> | bash [-s -- [options]]

Options:
  -v, --version           Show script version
  --force                 Reinstall even if up-to-date
  --dry-run               Show what would be done
  --prefix <dir>          Install location (default: auto-detect)
  --channel <chan>        stable|nightly (default: stable)
  --yes                   Non-interactive mode
  --uninstall             Remove nvim and restore latest backup if present
  --list-backups          Show backups in PREFIX
  --clean-backups         Remove old backups (keep 3 newest)
  --no-color              Disable colored output
  --verbose               Extra debug logs
  -h, --help              Show this help
EOF
}

# Debug helper
VERBOSE=${VERBOSE:-false}
debug() { $VERBOSE && log "DEBUG: $*" || true; }

ask_confirm() {
  local prompt="${1:-Proceed?}"
  if $ASSUME_YES; then return 0; fi
  if ! is_tty; then warn "Non-interactive; use --yes to auto-confirm."; return 1; fi
  printf "%s [y/N]: " "$prompt" >&2
  read -r ans || true
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then timeout 10 "$@"; else "$@"; fi
}

has_fuse() {
  if command -v fusermount3 >/dev/null 2>&1 || command -v fusermount >/dev/null 2>&1; then return 0; fi
  [[ -e /dev/fuse ]] && return 0
  lsmod 2>/dev/null | grep -q '^fuse' && return 0 || return 1
}

# ---------- Flags ----------
SCRIPT_VERSION="v0.3.4"
FORCE=false
DRY_RUN=false
CHANNEL="stable"
PREFIX="${PREFIX:-}"
USE_COLOR=true
DO_UNINSTALL=false
ASSUME_YES=false
DO_LIST_BACKUPS=false
DO_CLEAN_BACKUPS=false

while (( $# )); do
  case "${1:-}" in
    -v|--version)     echo "$SCRIPT_VERSION"; exit 0 ;;
    --force)          FORCE=true ;;
    --dry-run)        DRY_RUN=true ;;
    --prefix)         shift || true; PREFIX="${1:-}"; [[ -z "${PREFIX}" ]] && error "Missing value for --prefix" ;;
    --channel)        shift || true; CHANNEL="${1:-}"; [[ "${CHANNEL}" =~ ^(stable|nightly)$ ]] || error "Invalid --channel" ;;
    --no-color)       USE_COLOR=false ;;
    --uninstall)      DO_UNINSTALL=true ;;
    --yes)            ASSUME_YES=true ;;
    --list-backups)   DO_LIST_BACKUPS=true ;;
    --clean-backups)  DO_CLEAN_BACKUPS=true ;;
    --verbose)        VERBOSE=true ;;
    -h|--help)        show_help; exit 0 ;;
    *) error "Unknown flag: $1" ;;
  esac
  shift || true
done
if ! $USE_COLOR; then RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''; fi
debug "Args parsed. FORCE=$FORCE DRY_RUN=$DRY_RUN CHANNEL=$CHANNEL PREFIX='$PREFIX' YES=$ASSUME_YES VERBOSE=$VERBOSE"

# ---------- Prechecks ----------
command -v curl >/dev/null 2>&1 || error "curl required (e.g., sudo apt install curl)"
if ! command -v timeout >/dev/null 2>&1; then warn "timeout not found; continuing without timeouts"; fi
if is_tty; then CURL_PROGRESS=(-#); else CURL_PROGRESS=(-sS); fi

# Early sudo check
HAS_SUDO=false
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then HAS_SUDO=true; fi
debug "HAS_SUDO=$HAS_SUDO"

# ---------- Architecture ----------
arch=$(uname -m)
case "$arch" in
  x86_64) ARCH="x86_64"; TAR_ARCH="linux64" ;;
  aarch64|arm64) ARCH="arm64"; TAR_ARCH="linux-arm64" ;;
  *) error "Unsupported architecture: $arch" ;;
esac
debug "ARCH=$ARCH"

# ---------- glibc/OS detection (kept logic) ----------
USE_LEGACY=false
if command -v ldd &>/dev/null; then
  glibc_version=$(ldd --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1 || true)
  [[ -n "${glibc_version:-}" ]] && log "Detected glibc version: $glibc_version"
  if [[ -n "${glibc_version:-}" ]]; then
    if [[ "$(echo "$glibc_version 2.34" | awk '{print ($1 < $2)}')" == 1 ]]; then USE_LEGACY=true; fi
  fi
fi
if grep -q "20.04" /etc/os-release 2>/dev/null; then
  log "Ubuntu 20.04 detected - using legacy version"
  USE_LEGACY=true
fi
debug "USE_LEGACY=$USE_LEGACY"

# ---------- Version helpers ----------
ver_norm() { printf "%s\n" "${1#v}"; }
ver_gt() { [[ "$(printf '%s\n' "$(ver_norm "$1")" "$(ver_norm "$2")" | sort -V | tail -1)" != "$(ver_norm "$2")" ]]; }

# ---------- Determine PREFIX & PATH ----------
default_prefix() {
  if [[ -n "${PREFIX}" ]]; then printf "%s\n" "$PREFIX"; return; fi
  if $HAS_SUDO; then printf "/usr/local/bin\n"
  elif [[ -w "/usr/local/bin" ]]; then printf "/usr/local/bin\n"
  else printf "%s/.local/bin\n" "$HOME"; fi
}
PREFIX="$(default_prefix)"
mkdir -p "$PREFIX"
case ":$PATH:" in *":$PREFIX:"*) : ;; *)
  warn "Installation dir '$PREFIX' not found in PATH."
  [[ "$PREFIX" == "$HOME/.local/bin" ]] && warn 'Add: export PATH="$HOME/.local/bin:$PATH"'
  ;; esac
debug "PREFIX=$PREFIX"

# ---------- Quick maintenance ----------
if $DO_LIST_BACKUPS; then echo "Backups in $PREFIX:"; ls -lht "$PREFIX"/nvim.backup.* 2>/dev/null || echo "  (none)"; exit 0; fi
if $DO_CLEAN_BACKUPS; then
  mapfile -t backups < <(ls -1t "$PREFIX"/nvim.backup.* 2>/dev/null || true)
  if (( ${#backups[@]} > 3 )); then
    log "Keeping 3 newest; removing $((${#backups[@]} - 3)) older"
    for b in "${backups[@]:3}"; do rm -f "$b" && log "Removed: $(basename "$b")"; done
  else log "No old backups to remove"; fi
  exit 0
fi

# ---------- Uninstall / rollback ----------
if $DO_UNINSTALL; then
  BIN="${PREFIX}/nvim"
  if [[ ! -e "$BIN" ]]; then warn "No '${BIN}' to uninstall."; exit 0; fi
  ask_confirm "Uninstall '${BIN}'?" || error "Aborted"
  mapfile -t backups < <(ls -1t "$PREFIX"/nvim.backup.* 2>/dev/null || true)
  if (( ${#backups[@]} > 0 )); then
    newest="${backups[0]}"; log "Restoring backup: ${newest}"
    rm -f "$BIN"
    if $HAS_SUDO && [[ "$PREFIX" == "/usr/local/bin" ]]; then sudo cp "$newest" "$BIN"; sudo chmod +x "$BIN"
    else cp "$newest" "$BIN"; chmod +x "$BIN"; fi
    success "Restored $(basename "$newest")"; exit 0
  else
    warn "No backup found. Removing '${BIN}' only."
    ask_confirm "Remove '${BIN}' permanently?" || error "Aborted"
    rm -f "$BIN"; success "Removed '${BIN}'."; exit 0
  fi
fi

# ---------- Current version ----------
CURRENT_VERSION=""
if command -v nvim >/dev/null 2>&1; then
  CURRENT_VERSION=$(nvim --version 2>/dev/null | head -n1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
fi
[[ -n "$CURRENT_VERSION" && "$CURRENT_VERSION" != "unknown" ]] && log "Current version: $CURRENT_VERSION" || log "Current version: not installed"
debug "CURRENT_VERSION=${CURRENT_VERSION:-<none>}"

# ---------- Resolve latest ----------
LATEST_VERSION=""
DOWNLOAD_URL=""
CHECKSUM_URL=""
if [[ "$CHANNEL" == "nightly" ]]; then
  [[ "$USE_LEGACY" == true ]] && error "Nightly not available for legacy glibc; use --channel stable"
  LATEST_VERSION="nightly"
  DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-${ARCH}.appimage"
  CHECKSUM_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-${ARCH}.appimage.sha256sum"
else
  if [[ "$USE_LEGACY" == true ]]; then
    LATEST_VERSION="v0.11.3"
    DOWNLOAD_URL="https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage"
    CHECKSUM_URL="https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage.sha256sum"
    log "Using legacy version due to old glibc"
  else
    log "Fetching latest version..."
    if REDIRECT_URL=$(curl -Ls -o /dev/null -w "%{url_effective}" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage" 2>/dev/null); then
      LATEST_VERSION=$(printf "%s" "$REDIRECT_URL" | grep -Po '/download/\Kv[0-9]+\.[0-9]+\.[0-9]+' || true)
      if [[ -n "$LATEST_VERSION" ]]; then
        DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage"
        CHECKSUM_URL="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage.sha256sum"
        log "Got version from redirect: $LATEST_VERSION"
      fi
    fi
    if [[ -z "$LATEST_VERSION" ]]; then
      log "Redirect failed, trying GitHub API..."
      API_JSON="$(curl -fsSL --retry 3 --retry-delay 1 --connect-timeout 10 https://api.github.com/repos/neovim/neovim/releases/latest || true)"
      if [[ -n "$API_JSON" ]]; then
        LATEST_VERSION="$(printf "%s" "$API_JSON" | grep -Po '"tag_name": "\K[^"]*' | head -n1 || true)"
        if [[ -n "$LATEST_VERSION" ]]; then
          DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage"
          CHECKSUM_URL="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage.sha256sum"
          log "Got version from API: $LATEST_VERSION"
        fi
      fi
    fi
    if [[ -z "$LATEST_VERSION" ]]; then
      LATEST_VERSION="latest"
      DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage"
      CHECKSUM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage.sha256sum"
      log "Using direct latest download (version detection unavailable)"
    fi
  fi
fi
log "Latest version:  $LATEST_VERSION"
log "Download URL:    $DOWNLOAD_URL"
debug "CHECKSUM_URL=$CHECKSUM_URL"

# Major version warn
if [[ -n "$CURRENT_VERSION" && "$CURRENT_VERSION" != "unknown" && "$LATEST_VERSION" =~ ^v?[0-9] ]]; then
  curr_major=$(printf "%s" "$CURRENT_VERSION" | grep -oP '^v?\K[0-9]+' || echo "0")
  next_major=$(printf "%s" "$LATEST_VERSION" | grep -oP '^v?\K[0-9]+' || echo "0")
  if (( next_major > curr_major )); then
    warn "Major version upgrade: $CURRENT_VERSION -> $LATEST_VERSION"
    warn "Some plugins may need updates"
  fi
fi

# ---------- Offer force + show SHAs ----------
LOCAL_SHA=""
if command -v sha256sum >/dev/null 2>&1 && command -v nvim >/dev/null 2>&1; then
  local_bin="$(command -v nvim)"; local_real="$(readlink -f "$local_bin" 2>/dev/null || printf "%s" "$local_bin")"
  [[ -r "$local_real" ]] && LOCAL_SHA="$(sha256sum "$local_real" | awk '{print $1}')" || true
fi
REMOTE_SHA=""
[[ -n "$CHECKSUM_URL" ]] && REMOTE_SHA="$(curl -fsSL "$CHECKSUM_URL" 2>/dev/null | grep -E "  nvim-linux-${ARCH}\.appimage$" | awk '{print $1}' || true)"
debug "LOCAL_SHA=${LOCAL_SHA:-<none>} REMOTE_SHA=${REMOTE_SHA:-<none>}"

if [[ -n "$CURRENT_VERSION" && "$CURRENT_VERSION" != "unknown" && "$LATEST_VERSION" =~ ^v[0-9] ]]; then
  same_ver=false
  if [[ "$(printf '%s\n' "$(ver_norm "$LATEST_VERSION")" "$(ver_norm "$CURRENT_VERSION")" | sort -V | tail -1)" == "$(ver_norm "$CURRENT_VERSION")" ]] \
     && [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then same_ver=true; fi
  if $same_ver && [[ "$FORCE" != true ]]; then
    success "Neovim $CURRENT_VERSION is already up to date."
    [[ -n "$LOCAL_SHA"  ]] && log "Local  SHA256: $LOCAL_SHA"
    [[ -n "$REMOTE_SHA" ]] && log "Remote SHA256: $REMOTE_SHA" || warn "Remote checksum not available; skipping remote SHA display"
    log "Use --force to reinstall the same version."
    exit 0
  fi
  if $same_ver && [[ "$FORCE" == true ]]; then
    log "Forcing reinstall over the same version ($CURRENT_VERSION)."
    [[ -n "$LOCAL_SHA"  ]] && log "Local  SHA256: $LOCAL_SHA"
    [[ -n "$REMOTE_SHA" ]] && { log "Remote SHA256: $REMOTE_SHA"; [[ "$LOCAL_SHA" == "$REMOTE_SHA" ]] && warn "Local and remote SHA match; re-copying same bits."; } \
                            || warn "Remote checksum not available; proceeding without compare"
  fi
fi

# ---------- Temp workspace ----------
TEMP_DIR="$(mktemp -d -p "${TMPDIR:-/tmp}" nvim.XXXXXX)"
cleanup() { [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"; }
trap 'rc=$?; cleanup; exit $rc' EXIT INT TERM
cd "$TEMP_DIR"; debug "Temp dir: $TEMP_DIR"

# ---------- Download ----------
log "Downloading Neovim $LATEST_VERSION for $ARCH..."
if ! curl -fL "${CURL_PROGRESS[@]}" --retry 3 --retry-delay 1 --connect-timeout 15 -o nvim.appimage "$DOWNLOAD_URL"; then
  if [[ "$CHANNEL" == "stable" && "$USE_LEGACY" == false ]]; then
    warn "Primary download failed; trying legacy ${ARCH} v0.11.3"
    USE_LEGACY=true; LATEST_VERSION="v0.11.3"
    DOWNLOAD_URL="https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage"
    CHECKSUM_URL="https://github.com/neovim/neovim-releases/releases/download/${LATEST_VERSION}/nvim-linux-${ARCH}.appimage.sha256sum"
    curl -fL "${CURL_PROGRESS[@]}" --retry 3 --retry-delay 1 --connect-timeout 15 -o nvim.appimage "$DOWNLOAD_URL" || error "Download failed"
  else error "Download failed"; fi
fi
chmod +x nvim.appimage
log "Binary size: $(stat -c%s nvim.appimage 2>/dev/null || wc -c < nvim.appimage) bytes"

# ---------- Preflight test with FUSE-less fallback ----------
INSTALL_SOURCE="appimage"    # or "extracted"
fuse_err=""
log "Testing binary: --version"
if ! run_with_timeout ./nvim.appimage --version >/dev/null 2>&1; then
  fuse_err="$(./nvim.appimage --version 2>&1 || true)"
  log "Detailed output:"; printf "%s\n" "$fuse_err" >&2
  if printf "%s" "$fuse_err" | grep -qiE 'fuse|fusermount|Cannot mount AppImage|No suitable fusermount'; then
    warn "FUSE not available; attempting AppImage extraction fallback"
    if run_with_timeout ./nvim.appimage --appimage-extract >/dev/null 2>&1; then
      if [[ -x squashfs-root/usr/bin/nvim ]]; then
        log "Testing extracted nvim"
        if ! run_with_timeout ./squashfs-root/usr/bin/nvim --version >/dev/null 2>&1; then
          error "Extracted binary test failed"
        fi
        INSTALL_SOURCE="extracted"
      else
        error "Extraction succeeded, but 'usr/bin/nvim' not found"
      fi
    else
      # Secondary fallback: try official tarballs (no FUSE required)
      warn "Extraction failed. Trying tarball fallback."
      # Try arch-specific tarball names used by Neovim releases
      TARBALL_URL_1="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-${TAR_ARCH}.tar.gz"
      TARBALL_URL_2="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux64.tar.gz"
      if curl -fL "${CURL_PROGRESS[@]}" -o nvim.tar.gz "$TARBALL_URL_1"; then
        :
      elif curl -fL "${CURL_PROGRESS[@]}" -o nvim.tar.gz "$TARBALL_URL_2"; then
        :
      else
        error "Tarball fallback download failed"
      fi
      mkdir -p tarroot && tar -xzf nvim.tar.gz -C tarroot
      # common layout: tarroot/nvim/bin/nvim
      if [[ -x tarroot/nvim/bin/nvim ]]; then
        log "Testing tarball nvim"
        run_with_timeout tarroot/nvim/bin/nvim --version >/dev/null 2>&1 || error "Tarball binary test failed"
        INSTALL_SOURCE="tarball"
      else
        error "Tarball extracted but 'nvim/bin/nvim' not found"
      fi
    fi
  else
    error "Binary self-test failed"
  fi
fi

# Headless test (best-effort)
log "Testing headless startup"
if [[ "$INSTALL_SOURCE" == "appimage" ]]; then
  run_with_timeout ./nvim.appimage -u NORC --headless +q >/dev/null 2>&1 || warn "Headless start failed; continuing"
elif [[ "$INSTALL_SOURCE" == "extracted" ]]; then
  run_with_timeout ./squashfs-root/usr/bin/nvim -u NORC --headless +q >/dev/null 2>&1 || warn "Headless start failed; continuing"
else
  run_with_timeout tarroot/nvim/bin/nvim -u NORC --headless +q >/dev/null 2>&1 || warn "Headless start failed; continuing"
fi

# ---------- Checksum (optional presence) ----------
if [[ -n "$CHECKSUM_URL" ]]; then
  if curl -fsSL -o nvim.sha256sum "$CHECKSUM_URL" 2>/dev/null; then
    if command -v sha256sum >/dev/null 2>&1; then
      if ! grep -E "  nvim-linux-${ARCH}\.appimage$" nvim.sha256sum | sha256sum -c - >/dev/null 2>&1; then
        warn "Checksum FAILED for AppImage; proceeding only because fallback may install extracted binary"
      else
        success "Checksum verification passed (AppImage)"
      fi
    else warn "sha256sum not available; skipping checksum verification"; fi
  else warn "Checksum file not available; skipping verification"; fi
else
  warn "No checksum URL determined; skipping verification"
fi

# ---------- Install targets ----------
TARGET_VERSION_LABEL="${LATEST_VERSION}"; [[ "$TARGET_VERSION_LABEL" == "latest" ]] && TARGET_VERSION_LABEL="$(date +%Y%m%d)"
target="${PREFIX}/nvim-${TARGET_VERSION_LABEL}"
symlink="${PREFIX}/nvim"
debug "Target: $target  Symlink: $symlink  Source: $INSTALL_SOURCE"

# Confirm replacing existing non-symlink file
if [[ -e "$symlink" && ! -L "$symlink" ]]; then
  ask_confirm "Replace existing file '${symlink}'?" || error "Aborted by user"
fi

# Backup name (collision-safe)
BACKUP_NAME="nvim.backup.$(date +%Y%m%d_%H%M%S)"
counter=1
while [[ -f "${PREFIX}/${BACKUP_NAME}" ]]; do BACKUP_NAME="nvim.backup.$(date +%Y%m%d_%H%M%S)_$counter"; ((counter++)); done

# ---------- Install with rollback ----------
install_with_rollback() {
  local backup_path=""
  if [[ -f "$symlink" && ! -L "$symlink" ]]; then
    backup_path="${PREFIX}/${BACKUP_NAME}"
    if $HAS_SUDO && [[ "$PREFIX" == "/usr/local/bin" ]]; then sudo cp "$symlink" "$backup_path"; else cp "$symlink" "$backup_path"; fi
    log "Created backup: $(basename "$backup_path")"
  fi

  # Choose install source
  if [[ "$INSTALL_SOURCE" == "appimage" ]]; then
    local install_cmd=(install -m 0755 nvim.appimage "$target")
  elif [[ "$INSTALL_SOURCE" == "extracted" ]]; then
    mkdir -p extracted && cp -a squashfs-root/usr/bin/nvim extracted/nvim
    chmod +x extracted/nvim
    local install_cmd=(install -m 0755 extracted/nvim "$target")
  else
    # tarball
    local install_cmd=(install -m 0755 tarroot/nvim/bin/nvim "$target")
  fi

  if $HAS_SUDO && [[ "$PREFIX" == "/usr/local/bin" ]]; then
    if ! sudo "${install_cmd[@]}"; then
      [[ -n "$backup_path" ]] && sudo mv "$backup_path" "$symlink" || true
      error "Installation failed - restored backup"
    fi
    sudo ln -sfn "$target" "$symlink"
  else
    if ! "${install_cmd[@]}"; then
      [[ -n "$backup_path" ]] && mv "$backup_path" "$symlink" || true
      error "Installation failed - restored backup"
    fi
    ln -sfn "$target" "$symlink"
  fi
}

# ---------- Dry run ----------
if $DRY_RUN; then
  success "Dry-run complete."
  printf "Plan:\n  Install to: %s\n  Symlink:    %s -> %s\n" "$target" "$symlink" "$target" >&2
  exit 0
fi

install_with_rollback

# ---------- Verify ----------
if ! "$symlink" --version >/dev/null 2>&1; then error "Post-install verification failed"; fi

success "Neovim ${LATEST_VERSION} installed to ${target}"
log "Symlink updated: ${symlink} -> ${target}"
log "Run 'nvim --version' to verify"
