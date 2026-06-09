# Beszel Agent

The Beszel Agent runs on each system you want to monitor and communicates system metrics to the Beszel Hub.

## Prerequisites

Before installing, add the system in the Beszel Hub web interface. The Hub will provide you with a **Public Key** and **Token** required for installation.

## Installation

### Linux

Run the following command (replace the values from your Hub):

```bash
curl -sL https://get.beszel.dev -o /tmp/install-agent.sh && chmod +x /tmp/install-agent.sh && /tmp/install-agent.sh -p 45876 -k "<PUBLIC_KEY>" -t "<TOKEN>" -url "<HUB_URL>"
```

**Update:**
```bash
sudo /opt/beszel-agent/beszel-agent update && sudo systemctl restart beszel-agent
```

**Uninstall:**
```bash
/tmp/install-agent.sh -u
```

---

### macOS

Requires [Homebrew](https://brew.sh).

```bash
curl -sL https://get.beszel.dev/brew -o /tmp/install-agent-brew.sh && chmod +x /tmp/install-agent-brew.sh && /tmp/install-agent-brew.sh -p 45876 -k "<PUBLIC_KEY>" -t "<TOKEN>" -url "<HUB_URL>"
```

**Common commands:**
```bash
brew services info beszel-agent    # Check status
brew services stop beszel-agent    # Stop
brew services start beszel-agent   # Start
brew services restart beszel-agent # Restart
brew upgrade beszel-agent          # Upgrade
brew uninstall beszel-agent        # Uninstall
```

Logs: `~/.cache/beszel/beszel-agent.log`  
Config: `~/.config/beszel/beszel-agent.env`

---

### Windows

Open **PowerShell** and run:

```powershell
& iwr -useb https://get.beszel.dev -OutFile "$env:TEMP\install-agent.ps1"; & Powershell -ExecutionPolicy Bypass -File "$env:TEMP\install-agent.ps1" -Key "<PUBLIC_KEY>" -Port 45876 -Token "<TOKEN>" -Url "<HUB_URL>"
```

The script installs the agent as a Windows service using [NSSM](https://nssm.cc). It will automatically install Scoop or WinGet if neither is available.

**Common commands:**
```powershell
nssm status beszel-agent    # Check status
nssm stop beszel-agent      # Stop
nssm start beszel-agent     # Start
nssm restart beszel-agent   # Restart
nssm edit beszel-agent      # Edit configuration
```

Logs: `C:\ProgramData\beszel-agent\logs\beszel-agent.log`

---

### Docker

Create a `docker-compose.yml`:

```yaml
services:
  beszel-agent:
    image: henrygd/beszel-agent
    container_name: beszel-agent
    restart: unless-stopped
    network_mode: host
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./beszel_agent_data:/var/lib/beszel-agent
    environment:
      LISTEN: 45876
      KEY: "<PUBLIC_KEY>"
      TOKEN: "<TOKEN>"
      HUB_URL: "<HUB_URL>"
```

```bash
docker compose up -d
```

---

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `KEY` | SSH public key from Hub (required) | — |
| `LISTEN` | Port to listen on | `45876` |
| `TOKEN` | Token from Hub | — |
| `HUB_URL` | Hub URL | — |
| `MEM_CALC` | Memory calculation formula | — |
| `EXTRA_FILESYSTEMS` | Additional disks to monitor (e.g. `sdb`) | — |
| `DISK_USAGE_CACHE` | Cache duration for disk usage (e.g. `15m`) | — |

## Default Port

The agent listens on port **45876** by default. Make sure this port is accessible from the Hub.
