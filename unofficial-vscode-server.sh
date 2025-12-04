#!/usr/bin/env bash

# Modified Code-Server installation script
# Uses official Microsoft VS Code marketplace for extensions
# Based on: https://github.com/community-scripts/ProxmoxVE
# Modified by: biezz-2
# Fixed: Correct product.json location for Copilot support

function header_info {
cat <<"EOF"
   ______          __        _____                          
  / ____/___  ____/ /__     / ___/___  ______   _____  _____
 / /   / __ \/ __  / _ \    \__ \/ _ \/ ___/ | / / _ \/ ___/
/ /___/ /_/ / /_/ /  __/   ___/ /  __/ /   | |/ /  __/ /    
\____/\____/\__,_/\___/   /____/\___/_/    |___/\___/_/     
                    (Microsoft Marketplace Enabled)
 
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
APP="Code Server (Microsoft Marketplace)"
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

echo -e "\n${YW}Authentication Setup${CL}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
while true; do
read -p "Do you want to enable password authentication? (y/n): " auth_choice
case $auth_choice in
[Yy]*)
USE_AUTH="yes"
while true; do
read -sp "Enter password for Code Server: " PASSWORD1
echo
read -sp "Confirm password: " PASSWORD2
echo
if [ "$PASSWORD1" = "$PASSWORD2" ]; then
if [ -n "$PASSWORD1" ]; then
CODE_PASSWORD="$PASSWORD1"
break
else
echo -e "${RD}Password cannot be empty. Please try again.${CL}"
fi
else
echo -e "${RD}Passwords do not match. Please try again.${CL}"
fi
done
break
;;
[Nn]*)
USE_AUTH="no"
echo -e "${YW}Warning: Code Server will be accessible without authentication!${CL}"
break
;;
*)
echo "Please answer yes or no."
;;
esac
done
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
apt-get install -y jq &>/dev/null
msg_ok "Installed Dependencies"

VERSION=$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

msg_info "Installing Code-Server v${VERSION}"
curl -fOL https://github.com/coder/code-server/releases/download/v"$VERSION"/code-server_"${VERSION}"_amd64.deb &>/dev/null
dpkg -i code-server_"${VERSION}"_amd64.deb &>/dev/null
rm -rf code-server_"${VERSION}"_amd64.deb
msg_ok "Installed Code-Server v${VERSION}"

msg_info "Configuring Code-Server"
mkdir -p ~/.config/code-server/
mkdir -p ~/.local/share/code-server/User/
systemctl enable -q --now code-server@"$USER"

if [ "$USE_AUTH" = "yes" ]; then
cat <<EOF >~/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8680
auth: password
password: $CODE_PASSWORD
cert: false
app-name: "Visual Studio Code"
EOF
else
cat <<EOF >~/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8680
auth: none
password: 
cert: false
app-name: "Visual Studio Code"
EOF
fi

msg_info "Configuring Microsoft Marketplace (Copilot Support)"

PRODUCT_JSON_PATH=$(find /usr/lib -path "*/code-server*/lib/vscode/product.json" 2>/dev/null | head -1)

if [ -z "$PRODUCT_JSON_PATH" ]; then
echo -e "\n${RD}ERROR: Cannot find product.json location!${CL}"
exit 1
fi

cp "$PRODUCT_JSON_PATH" "$PRODUCT_JSON_PATH.backup"

cat <<EOF >"$PRODUCT_JSON_PATH"
{
"nameShort": "Code",
"nameLong": "Visual Studio Code",
"applicationName": "code",
"dataFolderName": ".vscode",
"win32MutexName": "vscode",
"licenseName": "MIT",
"licenseUrl": "https://github.com/microsoft/vscode/blob/main/LICENSE.txt",
"win32DirName": "Microsoft VS Code",
"win32NameVersion": "Microsoft Visual Studio Code",
"win32RegValueName": "VSCode",
"win32AppUserModelId": "Microsoft.VisualStudioCode",
"win32ShellNameShort": "Code",
"darwinBundleIdentifier": "com.microsoft.VSCode",
"reportIssueUrl": "https://github.com/microsoft/vscode/issues/new",
"urlProtocol": "vscode",
"extensionAllowedProposedApi": [],
"enableTelemetry": false,
"aiConfig": {
"ariaKey": "no-telemetry"
},
"extensionsGallery": {
"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
"cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
"itemUrl": "https://marketplace.visualstudio.com/items",
"controlUrl": "",
"recommendationsUrl": ""
}
}
EOF

cat <<EOF >~/.local/share/code-server/User/settings.json
{
"telemetry.telemetryLevel": "off",
"update.mode": "none",
"extensions.autoUpdate": true,
"extensions.autoCheckUpdates": true,
"workbench.colorTheme": "Default Dark+",
"security.workspace.trust.enabled": false
}
EOF

msg_ok "Configured Microsoft Marketplace"

msg_info "Restarting Code-Server"
systemctl restart code-server@"$USER"
sleep 3
msg_ok "Code-Server Restarted"

if systemctl is-active --quiet code-server@"$USER"; then
SERVICE_STATUS="${GN}Running${CL}"
else
SERVICE_STATUS="${RD}Failed${CL}"
fi

msg_ok "Installed ${APP} on $hostname"

echo -e "\n${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
echo -e "${GN}Installation Complete!${CL}\n"
echo -e "${APP} should be reachable at:"
echo -e "${BL}http://$IP:8680${CL}\n"

if [ "$USE_AUTH" = "yes" ]; then
echo -e "${YW}Authentication:${CL} ${GN}Enabled${CL}"
echo -e "${YW}Password:${CL} ${GN}(as configured)${CL}\n"
else
echo -e "${YW}Authentication:${CL} ${RD}Disabled${CL}"
echo -e "${YW}Warning:${CL} Anyone can access without password!\n"
fi

echo -e "${GN}✓${CL} Microsoft Visual Studio Marketplace: ${GN}Enabled${CL}"
echo -e "${GN}✓${CL} GitHub Copilot: ${GN}Should work now!${CL}"
echo -e "${GN}✓${CL} All official Microsoft extensions supported"
echo -e "\n${YW}Configuration:${CL}"
echo -e "  Config: ${BGN}~/.config/code-server/config.yaml${CL}"
echo -e "  Product: ${BGN}$PRODUCT_JSON_PATH${CL}"
echo -e "  Backup: ${BGN}$PRODUCT_JSON_PATH.backup${CL}"
echo -e "  Settings: ${BGN}~/.local/share/code-server/User/settings.json${CL}"
echo -e "\n${YW}Service Management:${CL}"
echo -e "  Status:  ${BGN}systemctl status code-server@$USER${CL}"
echo -e "  Restart: ${BGN}systemctl restart code-server@$USER${CL}"
echo -e "  Logs:    ${BGN}journalctl -u code-server@$USER -f${CL}"
echo -e "\n${YW}Install GitHub Copilot:${CL}"
echo -e "  1. Open Extensions (Ctrl+Shift+X)"
echo -e "  2. Search for 'GitHub Copilot'"
echo -e "  3. Click Install"
echo -e "  4. Sign in with GitHub"
echo -e "${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
