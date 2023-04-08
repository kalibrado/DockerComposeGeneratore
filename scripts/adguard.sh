#!/usr/bin/env bash
source "$PWD/bin/global.sh"

localhost=$(get_ip)

header "AdGuard"

DATA_DIR=$(ask "Path for data default(./app/AdGuard)" "./app/AdGuard")
HTTP=$(ask "HTTP port default(3000)" "3000")
HTTPS=$(ask "HTTPS port default(3001)" "3001")
HTTP_TCP=$(ask "HTTP TCP port default(3002)" "3002")
TCP_1=$(ask "TCP 1 port default(3003)" "3003")
TCP_2=$(ask "TCP 2 port default(3004)" "3004")
UDP_1=$(ask "UDP 1 port default(3005)" "3005")
UDP_2=$(ask "UDP 2 port default(3006)" "3006")

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}"/ || exit
mkdir -p ./work
mkdir -p ./conf

section "Create ${DATA_DIR}/docker-compose.yml"

cat <<EOF >./docker-compose.yml
version: '3.7'
services:
  adguardhome:
    image: adguard/adguardhome
    container_name: adguardhome
    ports:
      - ${localhost}:${TCP_1}:53/tcp
      - ${localhost}:${TCP_2}:853/tcp
      - ${localhost}:${UDP_1}:53/udp
      - ${localhost}:${UDP_2}:784/udp
      - ${localhost}:${HTTP}:3000/tcp
      - ${localhost}:${HTTP_TCP}:80/tcp
      - ${localhost}:${HTTPS}:443/tcp
    volumes:
      - ./work:/opt/adguardhome/work
      - ./conf:/opt/adguardhome/conf
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
EOF

ask_run "Access to adguard => http://${localhost}:${HTTP}"
