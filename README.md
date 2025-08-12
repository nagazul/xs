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
