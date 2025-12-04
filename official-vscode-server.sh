#!/usr/bin/env bash

# Modified script to install VS Code Server with original Visual Studio Code repository
# Updated: Use NPM instead of Yarn (VS Code 1.106+ requirement)

function header_info {
cat <<"EOF"
 _    _____    ______          __        _____                          
| |  / / (_)  / ____/___  ____/ /__     / ___/___  ______   _____  _____
| | / / / /  / /   / __ \/ __  / _ \    \__ \/ _ \/ ___/ | / / _ \/ ___/
| |/ / / /  / /___/ /_/ / /_/ /  __/   ___/ /  __/ /   | |/ /  __/ /    
|___/_/_/   \____/\____/\__,_/\___/   /____/\___/_/    |___/\___/_/     
                                                                         
EOF
}

IP=$(hostname -I | awk '{print $1}')
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
APP="VS Code Server (Original Repository)"
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
echo -e "${YW}Check logs above for details${CL}"
exit "$EXIT"
}

clear
header_info

echo -e "${YW}System Requirements Check${CL}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
echo -e "Total RAM: ${BL}${TOTAL_RAM}MB${CL}"
echo -e "Available RAM: ${BL}${FREE_RAM}MB${CL}"

if [ "$TOTAL_RAM" -lt 3500 ]; then
echo -e "${RD}ERROR: Need at least 4GB total RAM${CL}"
exit 1
fi
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

while true; do
read -p "This will Install ${APP} on $hostname. Proceed(y/n)?" yn
case $yn in
[Yy]*) break ;;
[Nn]*) exit ;;
*) echo "Please answer yes or no." ;;
esac
done

function msg_info() {
local msg="$1"
echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
local msg="$1"
echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_info "Installing Dependencies"
apt-get update >/dev/null 2>&1
apt-get install -y curl wget git jq build-essential libssl-dev pkg-config python3 libx11-dev libxkbfile-dev libsecret-1-dev >/dev/null 2>&1
msg_ok "Installed Dependencies"

msg_info "Installing Node.js v22"
if command -v node &>/dev/null; then
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 22 ]; then
apt-get remove -y nodejs >/dev/null 2>&1 || true
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null 2>&1
apt-get install -y nodejs >/dev/null 2>&1
fi
else
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null 2>&1
apt-get install -y nodejs >/dev/null 2>&1
fi
msg_ok "Installed Node.js $(node --version)"

msg_info "Fetching Latest VS Code Version"
VSCODE_VERSION=$(curl -fsSL https://api.github.com/repos/microsoft/vscode/releases/latest | jq -r '.tag_name')
msg_ok "Latest Version: ${VSCODE_VERSION}"

msg_info "Cloning VS Code Repository"
INSTALL_DIR="/opt/vscode-server"
rm -rf "$INSTALL_DIR" 2>/dev/null || true
git clone --depth 1 --branch "$VSCODE_VERSION" https://github.com/microsoft/vscode.git "$INSTALL_DIR" >/dev/null 2>&1
cd "$INSTALL_DIR"
msg_ok "Cloned VS Code Repository"

echo -e "\n${YW}Building VS Code - This takes 30-60 minutes${CL}\n"

msg_info "Installing Dependencies"
echo -e "\n${DGN}Running: npm install (15-30 min)${CL}"
npm install || exit 1
msg_ok "Installed Dependencies"

msg_info "Compiling VS Code"
echo -e "\n${DGN}Running: npm run compile (15-30 min)${CL}"
npm run compile || exit 1
msg_ok "Compiled VS Code"

msg_info "Creating Systemd Service"
cat <<EOF >/etc/systemd/system/vscode-server.service
[Unit]
Description=Visual Studio Code Server (Original)
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/node $INSTALL_DIR/out/server-main.js --host 0.0.0.0 --port 8680 --without-connection-token
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vscode-server
systemctl start vscode-server
msg_ok "Started Service"

PRODUCT_JSON="$INSTALL_DIR/product.json"
cp "$PRODUCT_JSON" "$PRODUCT_JSON.backup" 2>/dev/null || true
cat <<EOF >"$PRODUCT_JSON"
{
"nameShort": "Code",
"nameLong": "Visual Studio Code",
"applicationName": "code",
"dataFolderName": ".vscode",
"win32MutexName": "vscode",
"licenseName": "MIT",
"licenseUrl": "https://github.com/microsoft/vscode/blob/main/LICENSE.txt",
"extensionsGallery": {
"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
"itemUrl": "https://marketplace.visualstudio.com/items",
"cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
"controlUrl": ""
}
}
EOF

msg_ok "Installed ${APP}"

echo -e "\n${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
echo -e "${GN}Installation Complete!${CL}\n"
echo -e "${BL}http://$IP:8680${CL}\n"
echo -e "Service: ${BGN}systemctl status vscode-server${CL}"
echo -e "${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
