#!/usr/bin/env bash
# ========================================================
#  FUNCTIONS
# ========================================================
function header {
    printf "=%.0s" $(seq 1 "$(expr "$(tput cols)" / 4)")
    printf " %s " "$(echo "$1" | tr '[:lower:]' '[:upper:]')"
    printf "=%.0s" $(seq 1 "$(expr "$(tput cols)" / 4)")
    echo " "
}
function get_ip {
    localhost=$(hostname -I | cut -d ' ' -f1)
    echo "$localhost"
}
function ask {
    read -r -p "  -> $1 : " user_res
    local res=${user_res:-"$2"}
    echo "$res"
}
# ========================================================
#  START SCRIPTS
# ========================================================
localhost=$(get_ip)

header "PORTAINER"

DATA_DIR=$(ask "Path for data default(./app/Portainer)" "./app/Portainer")
HTTP_PORT=$(ask "HTTP port default(8000)" "8000")
HTTPS_PORT=$(ask "HTTPS port default(9443)" "9443")

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./data

echo "Create ${DATA_DIR}/docker-compose.yml"

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

echo "Access to portainer => https://${localhost}:${HTTPS_PORT}"
echo "Access to portainer => https://${localhost}:${HTTPS_PORT}"
