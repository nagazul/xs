# xs - DevOps Toolkit

Production-ready scripts for system administration and development environment setup.

## Podman Dev Container

Start a dev container with volume mounts, USB passthrough, and port forwarding:

```bash
mkdir -p "$HOME/containers/podman-dev-home"
podman run -d --name podman-dev --init --userns=keep-id \
  --security-opt label=disable \
  --device /dev/bus/usb -v /dev/bus/usb:/dev/bus/usb \
  -p 8080:8080 -p 8081:8081 \
  -v "$HOME/containers/podman-dev-home:$HOME:Z" \
  -v "$HOME/dev:$HOME/dev:Z" \
  --pids-limit 4096 --cpus 4 --memory 8g \
  -w "$HOME/dev" ubuntu tail -f /dev/null
```

Enter the container and install tools:

```bash
# install dependencies (as root)
podman exec -u 0 podman-dev bash -c "apt update && apt install -y curl"

# add ~/.local/bin to PATH (where installers put binaries)
podman exec podman-dev bash -c 'echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc'

# enter container
podman exec -it podman-dev bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/codex.sh | bash
```

## Install Scripts

```bash
# neovim
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash -s -- --force
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash -s -- --clean

# codex
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/codex.sh | bash
```

## nvim.sh Details

- Auto-detects glibc version and architecture (x86_64/ARM64)
- Tests binary before installing (--version, headless startup)
- Versioned installs with symlink (`nvim` -> `nvim-v0.11.6`)
- Automatic backups with `--clean` to remove old versions
- `--force` to reinstall, `--dry-run` to preview
- Works on Ubuntu 20.04+, piped or local
