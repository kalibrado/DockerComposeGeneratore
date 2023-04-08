#!/usr/bin/env bash
source "$PWD/bin/global.sh"

localhost=$(get_ip)

header "Proxy Manager "

DATA_DIR=$(ask "Path for data default(./app/ProxyManager)" "./app/ProxyManager")
HTTP_DASHBOARD=$(ask "HTTP port dashboard default(81)" "81")
HTTP_PORT=$(ask "HTTP port default(80)" "80")
HTTPS_PORT=$(ask "HTTPS port default(443)" "443")
USER=$(ask "User name default(npm)" "npm")
PASS=$(ask "User pass default(npm)" "npm")

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./certs
mkdir -p ./data

section "Create ${DATA_DIR}/docker-compose.yml"

cat <<EOF >./docker-compose.yml
version: '3.7'
services:
  # The NGINX proxy. This is the only container exposed to the world.
  proxy-manager:
    container_name: proxy-manager
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - ${localhost}:${HTTP_PORT}:80
      - ${localhost}:${HTTP_DASHBOARD}:81
      - ${localhost}:${HTTPS_PORT}:443
    volumes:
      - ./data:/data
      - ./data/letsencrypt:/etc/letsencrypt
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DB_MYSQL_HOST:"db"
      DB_MYSQL_PORT:3306
      MYSQL_USER:${USER}
      MYSQL_PASSWORD:${PASS}
      DB_MYSQL_NAME:"nginx"
    depends_on:
      - db
  db:
    image: 'jc21/mariadb-aria:latest'
    container_name: nginx-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD:'npm'
      MYSQL_DATABASE:'nginx'
      MYSQL_USER:${USER}
      MYSQL_PASSWORD:${PASS}
    volumes:
      - ./data/mysql:/var/lib/mysql
EOF

section "Create docker network bridge nginx-proxy-manager"
docker network create --driver bridge nginx-proxy-manager

ask_run "Default Proxy Manager username: admin@example.com" \
  "Default Proxy Manager password: changeme" \
  "Access to proxy-manager => http://${localhost}:${HTTP_DASHBOARD}"