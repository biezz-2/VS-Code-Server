     #!/usr/bin/env bash
     
     # Modified Code-Server installation script
     # Uses official Microsoft VS Code marketplace for extensions
     # Easier installation compared to building from source
     
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
     apt-get install -y curl git jq &>/dev/null
     msg_ok "Installed Dependencies"
     
     VERSION=$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest |
       grep "tag_name" |
       awk '{print substr($2, 3, length($2)-4) }')
     
     msg_info "Installing Code-Server v${VERSION}"
     curl -fOL https://github.com/coder/code-server/releases/download/v"$VERSION"/code-server_"${VERSION}"_amd64.deb &>/dev/null
     dpkg -i code-server_"${VERSION}"_amd64.deb &>/dev/null
     rm -rf code-server_"${VERSION}"_amd64.deb
     msg_ok "Installed Code-Server v${VERSION}"
     
     msg_info "Configuring Code-Server with Microsoft Marketplace"
     mkdir -p ~/.config/code-server/
     mkdir -p ~/.local/share/code-server/User/
     
     # Configure code-server to use Microsoft marketplace
     cat <<EOF >~/.config/code-server/config.yaml
     bind-addr: 0.0.0.0:8680
     auth: none
     password: 
     cert: false
     app-name: "Visual Studio Code"
     EOF
     
     # Create product.json to enable Microsoft marketplace
     PRODUCT_JSON=~/.local/share/code-server/product.json
     cat <<EOF >"$PRODUCT_JSON"
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
     
     # User settings to disable telemetry and auto-update
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
     
     msg_info "Starting Code-Server Service"
     systemctl enable -q --now code-server@"$USER"
     systemctl restart code-server@"$USER"
     msg_ok "Started Code-Server Service"
     
     # Wait for service to start
     sleep 3
     
     # Verify service is running
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
     echo -e "${YW}Service Status:${CL} $SERVICE_STATUS\n"
     echo -e "${YW}Features Enabled:${CL}"
     echo -e "✓ Microsoft Visual Studio Marketplace"
     echo -e "✓ Official VS Code Extensions"
     echo -e "✓ No authentication (change in config if needed)"
     echo -e "✓ Accessible from any device on network"
     echo -e "\n${YW}Configuration Files:${CL}"
     echo -e "- Config: ${BGN}~/.config/code-server/config.yaml${CL}"
     echo -e "- Product: ${BGN}~/.local/share/code-server/product.json${CL}"
     echo -e "- Settings: ${BGN}~/.local/share/code-server/User/settings.json${CL}"
     echo -e "\n${YW}Manage Service:${CL}"
     echo -e "- Start:   ${BGN}systemctl start code-server@\$USER${CL}"
     echo -e "- Stop:    ${BGN}systemctl stop code-server@\$USER${CL}"
     echo -e "- Restart: ${BGN}systemctl restart code-server@\$USER${CL}"
     echo -e "- Status:  ${BGN}systemctl status code-server@\$USER${CL}"
     echo -e "- Logs:    ${BGN}journalctl -u code-server@\$USER -f${CL}"
     echo -e "\n${YW}Enable Password (Optional):${CL}"
     echo -e "Edit ~/.config/code-server/config.yaml and set:"
     echo -e "  auth: password"
     echo -e "  password: your_password_here"
     echo -e "Then restart: ${BGN}systemctl restart code-server@\$USER${CL}"
     echo -e "${GN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
