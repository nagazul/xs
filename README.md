# xs - DevOps Toolkit 🛠️

Production-ready scripts for system administration and development environment setup.

## 🚀 Quick Install

**Install Latest Neovim:**
```bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash
```

**Force Reinstall:**
```bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash -s -- --force
```

**Clean Old Backups:**
```bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash -s -- --clean
```

**Install Codex:**
```bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/codex.sh | bash
```

## 📥 Local Usage

```bash
# Clone and run locally
git clone https://github.com/nagazul/xs.git
cd xs
./install/nvim.sh --help
./install/nvim.sh --force
```

## 🔧 Development

**Bump Script Version:**
```bash
# Patch version bump (default)
make bump install/nvim.sh

# Minor/Major version bumps
make bump install/nvim.sh minor
make bump install/nvim.sh major

# Check all versions
make versions
```

## 📖 Using Neovim

After installation, Neovim is available system-wide:

```bash
# Start Neovim
nvim

# Check version
nvim --version

# Edit a file
nvim myfile.txt

# Configuration location
~/.config/nvim/
```

## ✨ Features

- ✅ **Smart compatibility** - Auto-detects glibc and architecture
- ✅ **Safe installation** - Tests binaries before installing
- ✅ **Automatic backups** - Daily backups with cleanup
- ✅ **Network resilient** - Multiple fallback methods
- ✅ **Cross-platform** - Ubuntu 20.04+, x86_64/ARM64

## 🐳 Podman Dev Container

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

## 🆘 Troubleshooting

**Permission Issues:**
```bash
sudo chown $USER:$USER /usr/local/bin/nvim
```

**Path Issues:**
```bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Clean Reinstall:**
```bash
sudo rm /usr/local/bin/nvim*
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash
```

---

⭐ **Star this repo if you find it useful!**
