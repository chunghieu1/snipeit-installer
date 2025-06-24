#!/bin/bash

set -e

# Get public IP address of VPS
IP=$(hostname -I | awk '{print $1}')

# Remove needrestart to avoid upgrade interruptions
apt remove -y needrestart >/dev/null 2>&1 || true
rm -f /etc/needrestart/needrestart.conf >/dev/null 2>&1 || true

# Disable automatic service restarts during unattended-upgrades
sed -i 's/^#\?Unattended-Upgrade::Automatic-Reboot.*/Unattended-Upgrade::Automatic-Reboot "false";/' /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null 2>&1 || true

# System update and upgrade (fully non-interactive)
apt update -y >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive \
  apt upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" >/dev/null 2>&1

# Install Docker and Docker Compose
apt install -y ca-certificates curl gnupg lsb-release >/dev/null 2>&1
mkdir -p /etc/apt/keyrings >/dev/null 2>&1
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg >/dev/null 2>&1

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt update -y >/dev/null 2>&1
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1

# Create working directory
mkdir -p ~/snipeit_docker >/dev/null 2>&1
cd ~/snipeit_docker

# Generate docker-compose.yml
cat > docker-compose.yml <<'EOF'
volumes:
  db_data:
  storage:

services:
  app:
    image: snipe/snipe-it:${APP_VERSION:-latest}
    restart: unless-stopped
    volumes:
      - storage:/var/lib/snipeit
    ports:
      - "${APP_PORT:-8000}:80"
    depends_on:
      db:
        condition: service_healthy
        restart: true
    env_file:
      - .env

  db:
    image: mariadb:11.5.2
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USERNAME}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      timeout: 1s
      retries: 5
EOF

# Generate .env file with IP injected into APP_URL
cat > .env <<EOF
APP_VERSION=
APP_PORT=80

APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:EPP9V9gqbCYsghihWBZ0v0pKxUxRsVn0jG92CbY/NgA=
APP_URL=http://$IP
APP_TIMEZONE='UTC'
APP_LOCALE=en-US
MAX_RESULTS=500

PRIVATE_FILESYSTEM_DISK=local
PUBLIC_FILESYSTEM_DISK=local_public

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT='3306'
DB_DATABASE=snipeit
DB_USERNAME=snipeit
DB_PASSWORD=changeme1234
MYSQL_ROOT_PASSWORD=changeme1234
DB_PREFIX=null
DB_DUMP_PATH='/usr/bin'
DB_DUMP_SKIP_SSL=true
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_unicode_ci

DB_SSL=false
DB_SSL_IS_PAAS=false
DB_SSL_KEY_PATH=null
DB_SSL_CERT_PATH=null
DB_SSL_CA_PATH=null
DB_SSL_CIPHER=null
DB_SSL_VERIFY_SERVER=null

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_TLS_VERIFY_PEER=true
MAIL_FROM_ADDR=you@example.com
MAIL_FROM_NAME='Snipe-IT'
MAIL_REPLYTO_ADDR=you@example.com
MAIL_REPLYTO_NAME='Snipe-IT'
MAIL_AUTO_EMBED_METHOD='attachment'

ALLOW_BACKUP_DELETE=false
ALLOW_DATA_PURGE=false

IMAGE_LIB=gd

MAIL_BACKUP_NOTIFICATION_DRIVER=null
MAIL_BACKUP_NOTIFICATION_ADDRESS=null

SESSION_LIFETIME=12000
EXPIRE_ON_CLOSE=false
ENCRYPT=false
COOKIE_NAME=snipeit_session
COOKIE_DOMAIN=null
SECURE_COOKIES=false
API_TOKEN_EXPIRATION_YEARS=40

APP_TRUSTED_PROXIES=192.168.1.1,10.0.0.1,172.16.0.0/12
ALLOW_IFRAMING=false
REFERRER_POLICY=same-origin
ENABLE_CSP=false
CORS_ALLOWED_ORIGINS=null
ENABLE_HSTS=false

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_DRIVER=sync
CACHE_PREFIX=snipeit

REDIS_HOST=null
REDIS_PASSWORD=null
REDIS_PORT=6379

MEMCACHED_HOST=null
MEMCACHED_PORT=null

PUBLIC_AWS_SECRET_ACCESS_KEY=null
PUBLIC_AWS_ACCESS_KEY_ID=null
PUBLIC_AWS_DEFAULT_REGION=null
PUBLIC_AWS_BUCKET=null
PUBLIC_AWS_URL=null
PUBLIC_AWS_BUCKET_ROOT=null

PRIVATE_AWS_ACCESS_KEY_ID=null
PRIVATE_AWS_SECRET_ACCESS_KEY=null
PRIVATE_AWS_DEFAULT_REGION=null
PRIVATE_AWS_BUCKET=null
PRIVATE_AWS_URL=null
PRIVATE_AWS_BUCKET_ROOT=null

AWS_ACCESS_KEY_ID=null
AWS_SECRET_ACCESS_KEY=null
AWS_DEFAULT_REGION=null

LOGIN_MAX_ATTEMPTS=5
LOGIN_LOCKOUT_DURATION=60
RESET_PASSWORD_LINK_EXPIRES=900

LOG_CHANNEL=stderr
LOG_MAX_DAYS=10
APP_LOCKED=false
APP_CIPHER=AES-256-CBC
APP_FORCE_TLS=false
GOOGLE_MAPS_API=
LDAP_MEM_LIM=500M
LDAP_TIME_LIM=600
EOF

# Start container silently
docker compose up -d >/dev/null 2>&1
