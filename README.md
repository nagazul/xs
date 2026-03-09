## Podman Dev Container

Start a dev container with volume mounts, USB passthrough, and port forwarding:

```bash
mkdir -p "$HOME/containers/podman-dev-home" "$HOME/dev"
podman run -d --name podman-dev --init --userns=keep-id \
  --security-opt label=disable \
  --device /dev/bus/usb -v /dev/bus/usb:/dev/bus/usb \
  -p 8080:8080 -p 8081:8081 \
  -v "$HOME/containers/podman-dev-home:$HOME:Z" \
  -v "$HOME/dev:$HOME/dev:Z" \
  --pids-limit 4096 --cpus 4 --memory 8g \
  -w "$HOME/dev" ubuntu tail -f /dev/null
```

```bash
# install dependencies (as root)
podman exec -u 0 podman-dev bash -c "apt update && apt install -y curl git tig entr"

# add ~/.local/bin to PATH (where installers put binaries)
podman exec podman-dev bash -c 'echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc'

# enter container
podman exec -it podman-dev bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/nvim.sh | bash
curl -fsSL https://raw.githubusercontent.com/nagazul/xs/main/install/codex.sh | bash
```
