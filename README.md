# Beszel Agent

Beszel Agent 運行於每台受監控的主機上，負責收集系統指標並回傳給 Beszel Hub。

## 安裝前置作業

安裝前，請先在 Beszel Hub 網頁介面新增系統。Hub 會提供安裝所需的**公鑰（Public Key）**與 **Token**。

## 安裝方式

### Linux

將以下指令中的參數替換為 Hub 提供的資訊後執行：

```bash
curl -sL https://get.beszel.dev -o /tmp/install-agent.sh && chmod +x /tmp/install-agent.sh && /tmp/install-agent.sh -p 45876 -k "<PUBLIC_KEY>" -t "<TOKEN>" -url "<HUB_URL>"
```

**更新：**
```bash
sudo /opt/beszel-agent/beszel-agent update && sudo systemctl restart beszel-agent
```

**卸載：**
```bash
/tmp/install-agent.sh -u
```

---

### macOS

需要先安裝 [Homebrew](https://brew.sh)。

```bash
curl -sL https://get.beszel.dev/brew -o /tmp/install-agent-brew.sh && chmod +x /tmp/install-agent-brew.sh && /tmp/install-agent-brew.sh -p 45876 -k "<PUBLIC_KEY>" -t "<TOKEN>" -url "<HUB_URL>"
```

**常用指令：**
```bash
brew services info beszel-agent    # 查看狀態
brew services stop beszel-agent    # 停止
brew services start beszel-agent   # 啟動
brew services restart beszel-agent # 重啟
brew upgrade beszel-agent          # 升級
brew uninstall beszel-agent        # 卸載
```

Log 路徑：`~/.cache/beszel/beszel-agent.log`  
設定檔路徑：`~/.config/beszel/beszel-agent.env`

---

### Windows

開啟 **PowerShell** 執行：

```powershell
& iwr -useb https://get.beszel.dev -OutFile "$env:TEMP\install-agent.ps1"; & Powershell -ExecutionPolicy Bypass -File "$env:TEMP\install-agent.ps1" -Key "<PUBLIC_KEY>" -Port 45876 -Token "<TOKEN>" -Url "<HUB_URL>"
```

腳本會使用 [NSSM](https://nssm.cc) 將 agent 安裝為 Windows 服務，並自動安裝 Scoop 或 WinGet（若尚未安裝）。

**常用指令：**
```powershell
nssm status beszel-agent    # 查看狀態
nssm stop beszel-agent      # 停止
nssm start beszel-agent     # 啟動
nssm restart beszel-agent   # 重啟
nssm edit beszel-agent      # 編輯設定
```

Log 路徑：`C:\ProgramData\beszel-agent\logs\beszel-agent.log`

---

### Docker

建立 `docker-compose.yml`：

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

## 環境變數

| 變數 | 說明 | 預設值 |
|---|---|---|
| `KEY` | Hub 提供的 SSH 公鑰（必填） | — |
| `LISTEN` | 監聽埠號 | `45876` |
| `TOKEN` | Hub 提供的 Token | — |
| `HUB_URL` | Hub 的 URL | — |
| `MEM_CALC` | 記憶體計算方式 | — |
| `EXTRA_FILESYSTEMS` | 額外監控的磁碟（例如 `sdb`） | — |
| `DISK_USAGE_CACHE` | 磁碟用量快取時間（例如 `15m`） | — |

## 預設埠號

Agent 預設監聽 **45876** 埠，請確保 Hub 能夠連線到此埠。
