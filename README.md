# Beszel Agent

Beszel Agent 運行於每台受監控的主機上，負責收集系統指標並回傳給 Beszel Hub。

---

## 安裝前準備

安裝前，請先在 **Beszel Hub 後台 → 新增系統**，Hub 會提供以下三個必要資訊：

- **Hub URL**（例如 `https://monitor.example.com`）
- **Token**
- **Public Key**

---

## 方法一：下載安裝包（推薦，免指令）

前往 [Releases 頁面](https://github.com/LeoJ1mmy/beszel-agent/releases/latest) 下載對應版本。

### 選哪個版本？

| 你的系統 | 下載檔案 |
|----------|----------|
| 一般 Linux 伺服器 / VPS（64 位元） | `beszel-agent_linux_x86_64.tar.gz` |
| Raspberry Pi 4+ / ARM64 伺服器 | `beszel-agent_linux_arm64.tar.gz` |
| Raspberry Pi 2/3 / ARMv7 | `beszel-agent_linux_armv7.tar.gz` |
| Windows（64 位元） | `beszel-agent_windows_x86_64.zip` |

---

### Linux 安裝步驟

**1. 解壓縮**

```bash
tar -xzf beszel-agent_linux_x86_64.tar.gz
# 解壓後應有兩個檔案：beszel-agent 和 install.sh
```

**2. 執行安裝腳本**

```bash
sudo sh install.sh
```

依提示輸入 Hub URL、Token、Public Key，安裝完成後 agent 自動以系統服務啟動。

**常用管理指令**

```bash
systemctl status beszel-agent      # 查看狀態
journalctl -u beszel-agent -f      # 即時查看 log
systemctl stop beszel-agent        # 停止
systemctl restart beszel-agent     # 重啟
```

**卸載**

```bash
systemctl disable --now beszel-agent
rm /opt/beszel-agent/beszel-agent /etc/systemd/system/beszel-agent.service /etc/beszel-agent.env
```

---

### Windows 安裝步驟

**1. 解壓縮** `beszel-agent_windows_x86_64.zip`，取得以下兩個檔案：

```
beszel-agent.exe
install.bat
```

**2. 以系統管理員身份執行 `install.bat`**

在 `install.bat` 上按右鍵 → **以系統管理員身份執行**

依提示輸入 Hub URL、Token、Public Key，安裝完成後 agent 自動以 Windows 服務啟動，重開機後也會自動執行。

**常用管理指令**（在命令提示字元以系統管理員執行）

```bat
sc query beszel-agent              :: 查看狀態
sc stop beszel-agent               :: 停止
sc start beszel-agent              :: 啟動
```

**卸載**

```bat
sc stop beszel-agent
sc delete beszel-agent
```

---

## 方法二：命令列快速安裝

### Linux

```bash
curl -sL https://get.beszel.dev -o /tmp/install-agent.sh && chmod +x /tmp/install-agent.sh && /tmp/install-agent.sh -p 45876 -k "<PUBLIC_KEY>" -t "<TOKEN>" -url "<HUB_URL>"
```

更新：

```bash
sudo /opt/beszel-agent/beszel-agent update && sudo systemctl restart beszel-agent
```

### Windows（PowerShell）

```powershell
& iwr -useb https://get.beszel.dev -OutFile "$env:TEMP\install-agent.ps1"; & Powershell -ExecutionPolicy Bypass -File "$env:TEMP\install-agent.ps1" -Key "<PUBLIC_KEY>" -Port 45876 -Token "<TOKEN>" -Url "<HUB_URL>"
```

### Docker

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
|------|------|--------|
| `KEY` | Hub 提供的 SSH 公鑰（必填） | — |
| `HUB_URL` | Hub 的 URL（必填） | — |
| `TOKEN` | Hub 提供的 Token（必填） | — |
| `LISTEN` | 監聽埠號 | `45876` |
| `MEM_CALC` | 記憶體計算方式 | — |
| `EXTRA_FILESYSTEMS` | 額外監控的磁碟（例如 `sdb`） | — |
| `DISK_USAGE_CACHE` | 磁碟用量快取時間（例如 `15m`） | — |

> Agent 預設監聽 **45876** 埠，請確保 Hub 能連線到此埠。
