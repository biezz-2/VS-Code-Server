#!/usr/bin/env bash

# Modified Code-Server installation script with OAuth Support
# Uses official Microsoft VS Code marketplace for extensions
# Supports GitHub and Google login via OAuth2 Proxy
# Based on: https://github.com/community-scripts/ProxmoxVE
# Modified by: biezz-2

function header_info {
cat <<"EOF"
   ______          __        _____                          
  / ____/___  ____/ /__     / ___/___  ______   _____  _____
 / /   / __ \/ __  / _ \    \__ \/ _ \/ ___/ | / / _ \/ ___/
/ /___/ /_/ / /_/ /  __/   ___/ /  __/ /   | |/ /  __/ /    
\____/\____/\__,_/\___/   /____/\___/_/    |___/\___/_/     
         (Microsoft Marketplace + GitHub/Google OAuth)
 
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
APP="Code Server (Microsoft Marketplace + OAuth)"
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

echo -e "\n${YW}OAuth Authentication Setup${CL}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GN}Enable GitHub/Google login for AI features (Copilot, etc)${CL}\n"

USE_OAUTH="no"
OAUTH_PROVIDER=""

while true; do
    read -p "Enable OAuth login? (y/n): " oauth_choice
    case $oauth_choice in
        [Yy]*)
            USE_OAUTH="yes"
            echo -e "\n${YW}Select OAuth Provider:${CL}"
            echo "1) GitHub (recommended for Copilot)"
            echo "2) Google"
            echo "3) Both GitHub and Google"
            read -p "Choice (1-3): " provider_choice
            case $provider_choice in
                1) OAUTH_PROVIDER="github" ;;
                2) OAUTH_PROVIDER="google" ;;
                3) OAUTH_PROVIDER="both" ;;
                *) echo -e "${RD}Invalid choice${CL}"; continue ;;
            esac
            break
            ;;
        [Nn]*)
            USE_OAUTH="no"
            break
            ;;
        *)
            echo "Please answer yes or no."
            ;;
    esac
done

if [ "$USE_OAUTH" = "yes" ]; then
    echo -e "\n${YW}OAuth Configuration${CL}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    OAUTH_SECRET=$(openssl rand -hex 16)
    
    if [ "$OAUTH_PROVIDER" = "github" ] || [ "$OAUTH_PROVIDER" = "both" ]; then
        echo -e "\n${GN}GitHub OAuth Setup:${CL}"
        echo -e "1. Go to: ${BL}https://github.com/settings/developers${CL}"
        echo -e "2. Create 'New OAuth App'"
        echo -e "3. Homepage URL: ${BL}http://$IP:8680${CL}"
        echo -e "4. Callback URL: ${BL}http://$IP:4180/oauth2/callback${CL}"
        echo ""
        read -p "Enter GitHub Client ID: " GITHUB_CLIENT_ID
        read -sp "Enter GitHub Client Secret: " GITHUB_CLIENT_SECRET
        echo ""
    fi
    
    if [ "$OAUTH_PROVIDER" = "google" ] || [ "$OAUTH_PROVIDER" = "both" ]; then
        echo -e "\n${GN}Google OAuth Setup:${CL}"
        echo -e "1. Go to: ${BL}https://console.cloud.google.com/apis/credentials${CL}"
        echo -e "2. Create 'OAuth 2.0 Client ID'"
        echo -e "3. Authorized redirect URIs: ${BL}http://$IP:4180/oauth2/callback${CL}"
        echo ""
        read -p "Enter Google Client ID: " GOOGLE_CLIENT_ID
        read -sp "Enter Google Client Secret: " GOOGLE_CLIENT_SECRET
        echo ""
        read -p "Enter allowed email domain (e.g., gmail.com or * for all): " GOOGLE_DOMAIN
    fi
fi

echo -e "\n${YW}Basic Authentication Setup${CL}"
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
apt-get install -y wget &>/dev/null
msg_ok "Installed Dependencies"

if [ "$USE_OAUTH" = "yes" ]; then
    msg_info "Installing OAuth2 Proxy"
    OAUTH_PROXY_VERSION=$(curl -fsSL https://api.github.com/repos/oauth2-proxy/oauth2-proxy/releases/latest | grep "tag_name" | awk -F'"' '{print $4}' | sed 's/v//')
    wget -q https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v${OAUTH_PROXY_VERSION}/oauth2-proxy-v${OAUTH_PROXY_VERSION}.linux-amd64.tar.gz
    tar -xzf oauth2-proxy-v${OAUTH_PROXY_VERSION}.linux-amd64.tar.gz
    mv oauth2-proxy-v${OAUTH_PROXY_VERSION}.linux-amd64/oauth2-proxy /usr/local/bin/
    chmod +x /usr/local/bin/oauth2-proxy
    rm -rf oauth2-proxy-v${OAUTH_PROXY_VERSION}*
    msg_ok "Installed OAuth2 Proxy v${OAUTH_PROXY_VERSION}"
fi

VERSION=$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

msg_info "Installing Code-Server v${VERSION}"
DOWNLOAD_URL="https://github.com/coder/code-server/releases/download/v${VERSION}/code-server_${VERSION}_amd64.deb"

set +e  # Disable errexit temporarily
curl -sL -o code-server_"${VERSION}"_amd64.deb "$DOWNLOAD_URL"
CURL_EXIT=$?
set -e  # Re-enable errexit

if [ $CURL_EXIT -ne 0 ] || [ ! -f code-server_"${VERSION}"_amd64.deb ]; then
    echo -e "\n${RD}Failed to download Code-Server (exit code: $CURL_EXIT)${CL}"
    echo "URL: $DOWNLOAD_URL"
    echo "Please check your internet connection or try again later."
    exit 1
fi

dpkg -i code-server_"${VERSION}"_amd64.deb &>/dev/null
rm -rf code-server_"${VERSION}"_amd64.deb
mkdir -p ~/.config/code-server/
mkdir -p ~/.local/share/code-server/User/
systemctl enable -q --now code-server@"$USER"

if [ "$USE_AUTH" = "yes" ]; then
cat <<EOF >~/.config/code-server/config.yaml
bind-addr: 127.0.0.1:8680
auth: password
password: $CODE_PASSWORD
cert: false
app-name: "Visual Studio Code"
EOF
else
cat <<EOF >~/.config/code-server/config.yaml
bind-addr: 127.0.0.1:8680
auth: none
password: 
cert: false
app-name: "Visual Studio Code"
EOF
fi

cat <<EOF >~/.local/share/code-server/product.json
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
  "extensionAllowedProposedApi": [
    "github.copilot",
    "github.copilot-chat"
  ],
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
  "security.workspace.trust.enabled": false,
  "github.copilot.enable": {
    "*": true
  },
  "github.copilot.advanced": {}
}
EOF

systemctl restart code-server@"$USER"
msg_ok "Installed Code-Server v${VERSION} on $hostname"

if [ "$USE_OAUTH" = "yes" ]; then
    msg_info "Configuring OAuth2 Proxy"
    
    mkdir -p /etc/oauth2-proxy
    
    PROVIDER_CONFIG=""
    if [ "$OAUTH_PROVIDER" = "github" ]; then
        PROVIDER_CONFIG="provider = \"github\""
        PROVIDER_CONFIG="${PROVIDER_CONFIG}\ngithub_org = \"\""
        PROVIDER_CONFIG="${PROVIDER_CONFIG}\ngithub_team = \"\""
    elif [ "$OAUTH_PROVIDER" = "google" ]; then
        PROVIDER_CONFIG="provider = \"google\""
        if [ "$GOOGLE_DOMAIN" != "*" ]; then
            PROVIDER_CONFIG="${PROVIDER_CONFIG}\nwhitelist_domains = [\"${GOOGLE_DOMAIN}\"]"
        fi
    elif [ "$OAUTH_PROVIDER" = "both" ]; then
        PROVIDER_CONFIG="provider = \"github\""
        PROVIDER_CONFIG="${PROVIDER_CONFIG}\ngithub_org = \"\""
    fi
    
    cat <<EOF >/etc/oauth2-proxy/oauth2-proxy.cfg
http_address = "0.0.0.0:4180"
upstreams = ["http://127.0.0.1:8680/"]
email_domains = ["*"]
cookie_secret = "$OAUTH_SECRET"
cookie_secure = false
cookie_domains = [".${IP}", "${IP}"]
whitelist_domains = [".${IP}:4180", "${IP}:4180"]
${PROVIDER_CONFIG}
EOF

    if [ "$OAUTH_PROVIDER" = "github" ] || [ "$OAUTH_PROVIDER" = "both" ]; then
        cat <<EOF >>/etc/oauth2-proxy/oauth2-proxy.cfg
client_id = "$GITHUB_CLIENT_ID"
client_secret = "$GITHUB_CLIENT_SECRET"
EOF
    elif [ "$OAUTH_PROVIDER" = "google" ]; then
        cat <<EOF >>/etc/oauth2-proxy/oauth2-proxy.cfg
client_id = "$GOOGLE_CLIENT_ID"
client_secret = "$GOOGLE_CLIENT_SECRET"
EOF
    fi

    cat <<EOF >/etc/systemd/system/oauth2-proxy.service
[Unit]
Description=OAuth2 Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/oauth2-proxy --config=/etc/oauth2-proxy/oauth2-proxy.cfg
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable -q --now oauth2-proxy
    msg_ok "Configured OAuth2 Proxy"
fi

echo -e "\n${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
echo -e "${GN}Installation Complete!${CL}\n"

if [ "$USE_OAUTH" = "yes" ]; then
    echo -e "${APP} should be reachable at:"
    echo -e "${BL}http://$IP:4180${CL} ${GN}(with OAuth login)${CL}\n"
    
    echo -e "${YW}OAuth Authentication:${CL} ${GN}Enabled${CL}"
    if [ "$OAUTH_PROVIDER" = "github" ]; then
        echo -e "${YW}Provider:${CL} ${GN}GitHub${CL}"
        echo -e "${GN}✓${CL} GitHub Copilot will work seamlessly"
    elif [ "$OAUTH_PROVIDER" = "google" ]; then
        echo -e "${YW}Provider:${CL} ${GN}Google${CL}"
        echo -e "${YW}Allowed domain:${CL} ${GN}${GOOGLE_DOMAIN}${CL}"
    elif [ "$OAUTH_PROVIDER" = "both" ]; then
        echo -e "${YW}Providers:${CL} ${GN}GitHub & Google${CL}"
    fi
    echo ""
else
    echo -e "${APP} should be reachable at:"
    echo -e "${BL}http://$IP:8680${CL}\n"
fi

if [ "$USE_AUTH" = "yes" ] && [ "$USE_OAUTH" = "no" ]; then
    echo -e "${YW}Basic Authentication:${CL} ${GN}Enabled${CL}"
    echo -e "${YW}Password:${CL} ${GN}(as configured)${CL}\n"
elif [ "$USE_AUTH" = "no" ] && [ "$USE_OAUTH" = "no" ]; then
    echo -e "${YW}Authentication:${CL} ${RD}Disabled${CL}"
    echo -e "${YW}Warning:${CL} Anyone can access without password!\n"
fi

echo -e "${GN}✓${CL} Microsoft Visual Studio Marketplace: ${GN}Enabled${CL}"
echo -e "${GN}✓${CL} GitHub Copilot extensions: ${GN}Allowed${CL}"
echo -e "${GN}✓${CL} You can now install official Microsoft extensions"

if [ "$USE_OAUTH" = "yes" ]; then
    echo -e "\n${YW}How to use GitHub Copilot:${CL}"
    echo -e "1. Access VS Code via OAuth URL: ${BL}http://$IP:4180${CL}"
    echo -e "2. Login with your ${GN}${OAUTH_PROVIDER}${CL} account"
    echo -e "3. Install GitHub Copilot extension from marketplace"
    echo -e "4. Copilot will use your ${GN}${OAUTH_PROVIDER}${CL} session automatically"
fi

echo -e "\n${YW}Configuration Files:${CL}"
echo -e "  Config: ${BGN}~/.config/code-server/config.yaml${CL}"
echo -e "  Product: ${BGN}~/.local/share/code-server/product.json${CL}"
echo -e "  Settings: ${BGN}~/.local/share/code-server/User/settings.json${CL}"
if [ "$USE_OAUTH" = "yes" ]; then
    echo -e "  OAuth Config: ${BGN}/etc/oauth2-proxy/oauth2-proxy.cfg${CL}"
fi

echo -e "\n${YW}Service Management:${CL}"
echo -e "  Code-Server Status:  ${BGN}systemctl status code-server@$USER${CL}"
echo -e "  Code-Server Restart: ${BGN}systemctl restart code-server@$USER${CL}"
echo -e "  Code-Server Logs:    ${BGN}journalctl -u code-server@$USER -f${CL}"
if [ "$USE_OAUTH" = "yes" ]; then
    echo -e "  OAuth Proxy Status:  ${BGN}systemctl status oauth2-proxy${CL}"
    echo -e "  OAuth Proxy Restart: ${BGN}systemctl restart oauth2-proxy${CL}"
    echo -e "  OAuth Proxy Logs:    ${BGN}journalctl -u oauth2-proxy -f${CL}"
fi
echo -e "${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
