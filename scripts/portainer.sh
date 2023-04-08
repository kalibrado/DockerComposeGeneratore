#!/usr/bin/env bash
source "$PWD/bin/global.sh"

localhost=$(get_ip)

header "PORTAINER"

DATA_DIR=$(ask "Path for data default(./app/Portainer)" "./app/Portainer")
HTTP_PORT=$(ask "HTTP port default(8000)" "8000")
HTTPS_PORT=$(ask "HTTPS port default(9443)" "9443")

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./data

section "Create ${DATA_DIR}/docker-compose.yml"

cat <<EOF >./docker-compose.yml
version: '3.7'
services:
  agent:
    container_name: portainer-agent
    image: portainer/agent
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
  portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    command: -H tcp://agent:9001 --tlsskipverify
    ports:
      - ${localhost}:${HTTP_PORT}:8000
      - ${localhost}:${HTTPS_PORT}:9443
    volumes:
      - ./data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped

EOF

ask_run "Access to portainer => https://${localhost}:${HTTPS_PORT}" \
  "Access to portainer => https://${localhost}:${HTTPS_PORT}"
