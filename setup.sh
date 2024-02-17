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

# Install nvm, pnpm and pm2
echo "${CYAN}»   Installing NVM, PNPM and PM2 [1/3]"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.shrc" SHELL="$(which sh)" sh -
source ~/.shrc
npm install -g pm2
echo "${GREEN}»   NVM, PNPM and PM2 installed [1/3]"

# Install the panel
echo "${CYAN}»   Installing dependencies [2/3]"
cd web
pnpm install
cd ../api
pnpm install
echo "${GREEN}»   Dependencies installed [2/3]"

# Start the panel
echo "${CYAN}»   Starting the panel [3/3]"
cd web
pm2 start ecosystem.config.js
cd ../api
pm2 start ecosystem.config.js
pm2 save
pm2 startup
echo "${GREEN}»   Panel started [3/3]"
