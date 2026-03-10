## 🚀 ROC3 Dev Environment: Codex Edition

### 1. Host Preparation & Container Launch

```bash
mkdir -p ~/containers/roc3home ~/containers/roc3dev
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

```bash
podman exec -u 0 roc3 bash -c "apt update && apt install -y curl git tig entr golang-go mc xdg-utils psmisc lsof just jq nano"
podman exec roc3 bash -c 'echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc'

```

### 3. Install Tools (User)

```bash
podman exec -it roc3 bash
# Run your custom installers
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/codex.sh | bash
curl -fsSL https://app.factory.ai/cli | sh

```

### 4. Setup CLIProxyAPI (The Codex Bypass)

If your `codex.sh` didn't fetch the binary, do it manually here:

```bash
# Clone and build (or download binary)
cd ~/dev
git clone https://github.com/zhangrr/CLIProxyAPI.git
cd CLIProxyAPI
go build -o cli-proxy-api main.go

# Create the config
cat <<EOF > config.yaml
host: "0.0.0.0"
port: 8081
auth-dir: "/home/ubuntu/.cli-proxy-api"
api-keys: ["sk-factory-direct-link"]
oauth-model-alias:
  codex:
    - { name: "gpt-5.4", alias: "codex", fork: true }
codex-api-key: [{ api-key: "any-string" }]
debug: false
EOF

# One-time login
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

### 6. Verification & Daily Workflow

```bash
# 1. Start Proxy
cd ~/dev/CLIProxyAPI && nohup ./cli-proxy-api --config config.yaml > proxy.log 2>&1 &

# 2. VERIFY (Should show 'codex')
curl -H "Authorization: Bearer sk-factory-direct-link" http://localhost:8081/v1/models | jq

# 3. Start Droid
droid

```

---

### 7. Important Persistence Note

Your "Codex Key" is actually a file named `codex-*-enterprise.json` located in `~/containers/roc3home/.cli-proxy-api/`. As long as you keep that file, you stay logged in.

