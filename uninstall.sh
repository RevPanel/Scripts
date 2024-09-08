#!/bin/sh

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Check if the script is running as administrator
if [ "$(id -u)" != "0" ]; then
    echo "${RED}»   This script must be run as root! Restarting.."

    # Restart with sudo
    echo "${WHITE}"
    sudo sh "$0" "$@"
fi

# Join the RevPanel folder
cd /etc/revpanel || mkdir /etc/revpanel && cd /etc/revpanel

# Check if RevPanel is installed
if [ ! -f ".env" ]; then
    echo "${RED}»   RevPanel is not installed!"
    echo "${RED}»   If you want to install RevPanel, please run the installer"
    echo "${RESET}"
    exit 1
fi

# Print logo
echo "${PURPLE}"
cat << "EOF"
 _______                       _______                                __ 
|       \                     |       \                              |  \
| $$$$$$$\  ______  __     __ | $$$$$$$\ ______   _______    ______  | $$
| $$__| $$ /      \|  \   /  \| $$__/ $$|      \ |       \  /      \ | $$
| $$    $$|  $$$$$$\\$$\ /  $$| $$    $$ \$$$$$$\| $$$$$$$\|  $$$$$$\| $$
| $$$$$$$\| $$    $$ \$$\  $$ | $$$$$$$ /      $$| $$  | $$| $$    $$| $$
| $$  | $$| $$$$$$$$  \$$ $$  | $$     |  $$$$$$$| $$  | $$| $$$$$$$$| $$
| $$  | $$ \$$     \   \$$$   | $$      \$$    $$| $$  | $$ \$$     \| $$
 \$$   \$$  \$$$$$$$    \$     \$$       \$$$$$$$ \$$   \$$  \$$$$$$$ \$$
EOF
echo ""
echo ""
echo "                            ${GREEN}RevPanel Uninstaller v1.0.0"

# Stop the panel
echo "${CYAN}»   Stopping the panel [1/2]"
pm2 stop revpanel-web revpanel-api
pm2 delete revpanel-web revpanel-api
pm2 save
echo "${GREEN}»   Panel stopped [1/2]"

echo "${CYAN}»   Uninstalling the panel [3/2]"
rm -rf /etc/revpanel
rm -rf /var/lib/revpanel
echo "${GREEN}»   Panel successfully uninstalled [3/2]"
echo "${RESET}"