#!/bin/sh
set -e

# Beszel Agent Linux Installer
# Supports: systemd (Ubuntu/Debian/CentOS/RHEL/Fedora), OpenRC (Alpine)

INSTALL_DIR="/opt/beszel-agent"
BIN="$INSTALL_DIR/beszel-agent"
ENV_FILE="/etc/beszel-agent.env"
SERVICE_NAME="beszel-agent"

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()    { printf "${GREEN}[+]${RESET} %s\n" "$1"; }
warn()    { printf "${YELLOW}[!]${RESET} %s\n" "$1"; }
error()   { printf "${RED}[ERROR]${RESET} %s\n" "$1"; exit 1; }

# Check root
if [ "$(id -u)" -ne 0 ]; then
    error "This installer requires root privileges. Please run with sudo."
fi

echo ""
echo "============================================"
echo "   Beszel Agent Installer"
echo "============================================"
echo ""

# Collect configuration
echo "Please enter the following values from your Beszel Hub:"
echo "(Hub UI -> Add System)"
echo ""

printf "Hub URL (e.g. https://monitor.example.com): "
read -r HUB_URL
[ -z "$HUB_URL" ] && error "Hub URL cannot be empty."

printf "Token: "
read -r TOKEN
[ -z "$TOKEN" ] && error "Token cannot be empty."

printf "Public Key: "
read -r KEY
[ -z "$KEY" ] && error "Public Key cannot be empty."

echo ""
info "Installing to $INSTALL_DIR ..."

# Find the binary (same directory as this script)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$SCRIPT_DIR/beszel-agent"
if [ ! -f "$BINARY" ]; then
    error "beszel-agent binary not found. Make sure install.sh is in the same folder as beszel-agent."
fi

# Install binary
mkdir -p "$INSTALL_DIR"
cp "$BINARY" "$BIN"
chmod 755 "$BIN"
chown root:root "$BIN"

# Write env file
cat > "$ENV_FILE" <<EOF
HUB_URL=$HUB_URL
TOKEN=$TOKEN
KEY=$KEY
EOF
chmod 600 "$ENV_FILE"

info "Config written to $ENV_FILE"

# Create beszel user if it doesn't exist
if ! id beszel >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin beszel 2>/dev/null || \
    adduser -S -H -s /sbin/nologin beszel 2>/dev/null || true
fi

# Detect init system
if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
    INIT="systemd"
elif command -v rc-service >/dev/null 2>&1; then
    INIT="openrc"
else
    INIT="none"
fi

if [ "$INIT" = "systemd" ]; then
    info "Setting up systemd service..."
    cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=Beszel Agent
After=network.target

[Service]
User=beszel
EnvironmentFile=$ENV_FILE
ExecStart=$BIN
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # Set correct ownership for env file
    chown beszel:beszel "$ENV_FILE" 2>/dev/null || true

    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl restart $SERVICE_NAME

    sleep 2
    if systemctl is-active --quiet $SERVICE_NAME; then
        info "Beszel Agent is running!"
    else
        warn "Service may not have started. Check: journalctl -u $SERVICE_NAME -n 20"
    fi

elif [ "$INIT" = "openrc" ]; then
    info "Setting up OpenRC service..."
    cat > /etc/init.d/$SERVICE_NAME <<EOF
#!/sbin/openrc-run
name="beszel-agent"
description="Beszel Agent"
command="$BIN"
command_background=true
pidfile="/run/\${RC_SVCNAME}.pid"
command_user="beszel"

depend() {
    need net
}

start_pre() {
    set -a
    . $ENV_FILE
    set +a
}
EOF
    chmod +x /etc/init.d/$SERVICE_NAME
    rc-update add $SERVICE_NAME default
    rc-service $SERVICE_NAME start

    info "Beszel Agent installed (OpenRC)!"
else
    warn "No supported init system found (systemd/OpenRC)."
    warn "Start manually: $BIN"
fi

echo ""
echo "============================================"
printf "${GREEN}Installation complete!${RESET}\n"
echo ""
echo "Binary      : $BIN"
echo "Config      : $ENV_FILE"
echo ""
echo "Useful commands:"
echo "  Status  : systemctl status $SERVICE_NAME"
echo "  Logs    : journalctl -u $SERVICE_NAME -f"
echo "  Stop    : systemctl stop $SERVICE_NAME"
echo "  Remove  : systemctl disable --now $SERVICE_NAME && rm $BIN /etc/systemd/system/$SERVICE_NAME.service $ENV_FILE"
echo "============================================"
echo ""
