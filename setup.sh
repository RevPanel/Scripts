#!/bin/sh

domain=$1

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
postgresPassword=$(openssl rand -hex 16)
appToken=$(openssl rand -hex 16)

sudo -u postgres psql -c "CREATE USER revpanel WITH PASSWORD '$postgresPassword';"

# Configure the web panel
cd web

touch .env
echo "NODE_ENV=\"production\"" >> .env
echo "NEXT_PUBLIC_ENV=\"production\"" >> .env
echo "DATABASE_URL=\"postgresql://revpanel:$postgresPassword@localhost:5432/panel?schema=public\"" >>
echo "APP_URL=\"https://$domain\"" >> .env
echo "ADMIN_KEY=\"$appToken\"" >> .env

pm2 start ecosystem.config.js

# Configure the api
cd ../api

touch .env
echo "DATABASE_URL=\"postgresql://revpanel:$postgresPassword@localhost:5432/daemon?schema=public\"" >> .env
echo "API_TOKEN=\"$appToken\"" >> .env

pm2 start ecosystem.config.js

# Save and enable pm2
pm2 save
pm2 startup
echo "${GREEN}»   Panel started [3/3]"
