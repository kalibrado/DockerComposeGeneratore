#!/usr/bin/env bash
source "$PWD/bin/global.sh"

header "Duck DNS"

DATA_DIR=$(ask "Path for data default(./app/DuckDns)" "./app/DuckDns")
SUBDOMAINS=$(ask "Duck DNS subdomains (comma-separated, no spaces)")
TOKEN=$(ask "Duck dns token")

# Validate token
if ! curl --fail --silent --show-error "https://www.duckdns.org/update?domains=${SUBDOMAINS}&token=${TOKEN}&verbose=true"; then
  error_response "Invalid Duck DNS token"
  exit 1
fi

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./data

section "Create ${DATA_DIR}/docker-compose.yml"

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

ask_run
