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
header "Duck DNS"

DATA_DIR=$(ask "Path for data default(./app/DuckDns)" "./app/DuckDns")
SUBDOMAINS=$(ask "Duck DNS subdomains (comma-separated, no spaces)")
TOKEN=$(ask "Duck dns token")

# Validate token
if ! curl --fail --silent --show-error "https://www.duckdns.org/update?domains=${SUBDOMAINS}&token=${TOKEN}&verbose=true"; then
  echo "Invalid Duck DNS token"
  exit 1
fi

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./data

echo "Create ${DATA_DIR}/docker-compose.yml"

cat <<EOF >./docker-compose.yml
version: '3.7'
services:
services:
  duckdns:
    image: lscr.io/linuxserver/duckdns:latest
    container_name: duckdns
    environment:
      - SUBDOMAINS=${SUBDOMAINS}
      - TOKEN=${TOKEN}
      - LOG_FILE=true 
    volumes:
      - ./config:/config 
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
EOF
