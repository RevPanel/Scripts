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
mkdir -p /etc/revpanel && cd /etc/revpanel

# If already installed, exit
if [ -f ".env" ]; then
    echo "${RED}»   RevPanel is already installed!"
    echo "${RED}»   If you want to reinstall RevPanel, please uninstall first or remove the /etc/revpanel directory"
    echo "${RESET}"
    exit 1
fi

# --------------------------------------------
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
echo "                            ${GREEN}RevPanel Installer v2.0.0"
# --------------------------------------------

# -------------[ #1 DEPENDENCIES ]-------------
echo "${CYAN}»   Installing dependencies [1/4]"

sudo apt update
sudo apt install curl openssl certbot python3-certbot-nginx nginx -y

if ! [ -x "$(command -v docker)" ]; then
    sudo apt install docker.io docker-compose -y
    sudo systemctl enable --now docker
fi

if ! [ -x "$(command -v node)" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install nodejs -y
fi

corepack enable
npm install -g pm2

echo "${GREEN}»   Dependencies installed [1/4]"

# -------------[ #2 WEBSERVER ]-------------
echo "${CYAN}»   Setting up WebServer [2/4]"

echo "${WHITE}"
read -p "Enter your panel domain (e.g panel.example.com): " DOMAIN
certbot certonly --nginx -d ${DOMAIN} -d api.${DOMAIN} --non-interactive --agree-tos -m admin@${DOMAIN}

echo "server {
    server_name ${DOMAIN};

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    server_name api.${DOMAIN};

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/api.${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.${DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    if (\$host = ${DOMAIN}) {
        return 301 https://\$host\$request_uri;
    }

    if (\$host = api.${DOMAIN}) {
        return 301 https://\$host\$request_uri;
    }

    listen 80;
    server_name ${DOMAIN} api.${DOMAIN};
    return 404;
}" > /etc/nginx/sites-available/revpanel
ln -s /etc/nginx/sites-available/revpanel /etc/nginx/sites-enabled/revpanel
systemctl reload nginx

echo "${GREEN}»   WebServer setup complete [2/4]"

# -------------[ #3 CONFIGURATION ]-------------


echo "${CYAN}»   Configuring the panel [3/4]"
git clone https://github.com/RevPanel/Daemon daemon
git clone https://github.com/RevPanel/Panel web

POSTGRES_PASSWORD=$(openssl rand -hex 32)
API_TOKEN=$(openssl rand -hex 32)

sudo docker run --name revpanel-postgres -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} -p 127.0.0.1:5432:5432 --restart always -d postgres:16-alpine

cd daemon
pnpm install

echo "NODE_ENV=production
DATABASE_URL=postgres://postgres:${POSTGRES_PASSWORD}@localhost:3306/daemon
API_TOKEN=${API_TOKEN}" > .env

pnpm run migrate:run
pnpm build
pm2 start dist/main.js --name=revpanel-daemon

cd ../web
pnpm install

echo "NODE_ENV=production
DATABASE_URL=postgres://postgres:${POSTGRES_PASSWORD}@localhost:3306/panel
APP_URL=https://${DOMAIN}
BACKEND_URL=https://api.${DOMAIN}
ADMIN_KEY=${API_TOKEN}" > .env

pnpm run migrate:run
pnpm build

pm2 start .next/standalone/server.js --name=revpanel-web

pm2 save
pm2 startup

echo "${GREEN}»   Panel configured [3/4]"

# Start the panel
echo "${CYAN}»   Starting.. [4/4]"
sudo bash setup.sh ${DOMAIN}
echo "${GREEN}»   Panel successfully installed [4/4]"
echo "${RESET}"