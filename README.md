## 🚀 ROC3 Dev Environment: Codex Edition

Persistent Ubuntu dev environment on Ubuntu/Fedora with **CLIProxyAPI** pre-configured for an "Unlimited" Enterprise Codex bypass.

### 1. Host Preparation & Container Launch

Run on your **host machine** to create directories and start the container.

```bash
# Create persistent host directories
mkdir -p ~/containers/roc3home ~/containers/roc3dev

# Launch the container
podman run -d --name roc3 --init --userns=keep-id \
  --security-opt label=disable \
  --device /dev/bus/usb -v /dev/bus/usb:/dev/bus/usb \
  -p 8080:8080 -p 8081:8081 -p 1455:1455 \
  -v "$HOME/containers/roc3home:/home/ubuntu:Z" \
  -v "$HOME/containers/roc3dev:/home/ubuntu/dev:Z" \
  --pids-limit 4096 --cpus 4 --memory 8g \
  -w "/home/ubuntu/dev" ubuntu tail -f /dev/null

```

### 2. Provision Dependencies (Root)

Install system tools and set the environment path.

```bash
# Install packages as root
podman exec -u 0 roc3 bash -c "apt update && apt install -y curl git tig entr golang-go mc xdg-utils psmisc lsof just jq nano"

# Add local binaries to PATH
podman exec roc3 bash -c 'echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc'

```

### 3. Install Development Tools (User)

Enter the container to install Neovim, the Codex Proxy, and Factory Droid.

```bash
podman exec -it roc3 bash

# Inside the container:
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/codex.sh | bash
curl -fsSL https://app.factory.ai/cli | sh

```

### 4. Configure CLIProxyAPI (The Codex Bypass)

Map the `codex` nickname to your Enterprise session.

```bash
cat <<EOF > ~/dev/CLIProxyAPI/config.yaml
host: "0.0.0.0"
port: 8081
auth-dir: "/home/ubuntu/.cli-proxy-api"
api-keys:
  - "sk-factory-direct-link"
oauth-model-alias:
  codex:
    - name: "gpt-5.4"
      alias: "codex"
      fork: true
codex-api-key:
  - api-key: "any-string"
debug: false
usage-statistics-enabled: false
EOF

# Perform One-Time Login:
cd ~/dev/CLIProxyAPI
./cli-proxy-api --config config.yaml --codex-login

```

### 5. Link Factory Droid to Proxy

```bash
mkdir -p ~/.factory
cat <<EOF > ~/.factory/settings.json
{
  "customModels": [
    {
      "model": "codex",
      "displayName": "Codex Unlimited",
      "baseUrl": "http://127.0.0.1:8081/v1",
      "apiKey": "sk-factory-direct-link",
      "provider": "openai"
    }
  ]
}
EOF

```

### 6. Verification & Workflow

Before launching Droid, verify the proxy sees your Codex session:

```bash
# 1. Start Proxy in background
cd ~/dev/CLIProxyAPI && nohup ./cli-proxy-api --config config.yaml > proxy.log 2>&1 &

# 2. Verify the Model Bridge (You should see "codex" and "gpt-5.4" in the list)
curl -H "Authorization: Bearer sk-factory-direct-link" http://localhost:8081/v1/models | jq

# 3. Start Droid
droid

```

---

### 7. Key Paths for Host Access

* **Settings:** `~/containers/roc3home/.factory/settings.json`
* **Session Keys:** `~/containers/roc3home/.cli-proxy-api/`
* **Projects:** `~/containers/roc3dev/`
