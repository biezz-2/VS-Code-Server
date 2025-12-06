#!/usr/bin/env bash

# Official VS Code Server installation script
# Native GitHub authentication for Copilot
# Seamless AI features integration
# Based on: https://github.com/community-scripts/ProxmoxVE
# Modified by: biezz-2

function header_info {
cat <<"EOF"
   ______          __        _____                          
  / ____/___  ____/ /__     / ___/___  ______   _____  _____
 / /   / __ \/ __  / _ \    \__ \/ _ \/ ___/ | / / _ \/ ___/
/ /___/ /_/ / /_/ /  __/   ___/ /  __/ /   | |/ /  __/ /    
\____/\____/\__,_/\___/   /____/\___/_/    |___/\___/_/     
         (Official VS Code Server + GitHub Copilot)
 
EOF
}
IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname -f 2>/dev/null || hostname)
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
APP="Official VS Code Server"
hostname="$(hostname)"
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR

function error_exit() {
trap - ERR
local reason="Unknown failure occured."
local msg="${1:-$reason}"
local flag="${RD}‼ ERROR ${CL}$EXIT@$LINE"
echo -e "$flag $msg" 1>&2
exit "$EXIT"
}
clear
header_info
if command -v pveversion >/dev/null 2>&1; then
echo -e "⚠️  Can't Install on Proxmox "
exit
fi
if [ -e /etc/alpine-release ]; then
echo -e "⚠️  Can't Install on Alpine"
exit
fi
while true; do
read -p "This will Install ${APP} on $hostname. Proceed(y/n)?" yn
case $yn in
[Yy]*) break ;;
[Nn]*) exit ;;
*) echo "Please answer yes or no." ;;
esac
done

echo -e "\n${YW}Port Configuration${CL}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GN}Configure which port VS Code Server will use${CL}\n"
echo -e "Current IP: ${BL}$IP${CL}"
echo -e "Current Hostname: ${BL}$HOSTNAME${CL}\n"

while true; do
    read -p "Enter port number (default 8680): " PORT_INPUT
    if [ -z "$PORT_INPUT" ]; then
        PORT="8680"
        break
    elif [[ "$PORT_INPUT" =~ ^[0-9]+$ ]] && [ "$PORT_INPUT" -ge 1024 ] && [ "$PORT_INPUT" -le 65535 ]; then
        PORT="$PORT_INPUT"
        break
    else
        echo -e "${RD}Invalid port. Please enter a number between 1024-65535${CL}"
    fi
done

echo -e "\n${GN}VS Code Server will be accessible at: ${BL}http://${IP}:${PORT}${CL}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

function msg_info() {
local msg="$1"
echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
local msg="$1"
echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_info "Installing Dependencies"
apt-get update &>/dev/null
apt-get install -y curl &>/dev/null
apt-get install -y git &>/dev/null
apt-get install -y wget &>/dev/null
msg_ok "Installed Dependencies"

msg_info "Installing Official VS Code Server CLI"
set +e
curl -Lk "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" --output /tmp/vscode_cli.tar.gz
CURL_EXIT=$?
set -e

if [ $CURL_EXIT -ne 0 ] || [ ! -f /tmp/vscode_cli.tar.gz ]; then
    echo -e "\n${RD}Failed to download VS Code CLI (exit code: $CURL_EXIT)${CL}"
    echo "Please check your internet connection or try again later."
    exit 1
fi

tar -xzf /tmp/vscode_cli.tar.gz -C /usr/local/bin/
chmod +x /usr/local/bin/code
rm /tmp/vscode_cli.tar.gz
msg_ok "Installed Official VS Code Server"

msg_info "Configuring VS Code Server Service"
cat <<EOF >/etc/systemd/system/vscode-server.service
[Unit]
Description=Official VS Code Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/code serve-web --host 0.0.0.0 --port $PORT --without-connection-token --accept-server-license-terms
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q --now vscode-server
msg_ok "Configured VS Code Server"

echo -e "\n${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
echo -e "${GN}Installation Complete!${CL}\n"

echo -e "${APP} is now accessible at:"
echo -e "${BL}http://${IP}:${PORT}${CL}\n"

echo -e "${GN}✓${CL} Official Microsoft VS Code Server: ${GN}Installed${CL}"
echo -e "${GN}✓${CL} Native GitHub authentication: ${GN}Available${CL}"
echo -e "${GN}✓${CL} GitHub Copilot: ${GN}Full support${CL}"
echo -e "${GN}✓${CL} Microsoft Marketplace: ${GN}Native${CL}"

echo -e "\n${YW}How to use GitHub Copilot:${CL}"
echo -e "1. Open VS Code at: ${BL}http://${IP}:${PORT}${CL}"
echo -e "2. Click ${GN}Account icon${CL} (bottom right)"
echo -e "3. Select ${GN}'Sign in to use GitHub Copilot'${CL}"
echo -e "4. Choose ${GN}'Sign in with GitHub'${CL}"
echo -e "5. Authorize VS Code in your browser"
echo -e "6. ${GN}Done!${CL} Copilot is active ✨"

echo -e "\n${YW}Features:${CL}"
echo -e "  ${GN}✓${CL} No device code flow needed"
echo -e "  ${GN}✓${CL} Seamless authentication"
echo -e "  ${GN}✓${CL} Auto token refresh"
echo -e "  ${GN}✓${CL} Native GitHub integration"

echo -e "\n${YW}Service Management:${CL}"
echo -e "  Status:  ${BGN}systemctl status vscode-server${CL}"
echo -e "  Restart: ${BGN}systemctl restart vscode-server${CL}"
echo -e "  Logs:    ${BGN}journalctl -u vscode-server -f${CL}"
echo -e "${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
