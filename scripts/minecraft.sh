#!/usr/bin/env bash
source "$PWD/bin/global.sh"

localhost=$(get_ip)

header "minecraft"

DATA_DIR=$(ask "Path for data default(./app/Minecraft)" "./app/Minecraft")
PORT=$(ask "HTTP port default(25565)" "25565")

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./data

section "Create ${DATA_DIR}/docker-compose.yml"

cat <<EOF >./docker-compose.yml
version: '3.7'
services:
  minecraft:
    image: itzg/minecraft-server
    ports:
      - ${localhost}:${PORT}:25565
    environment:
      EULA: "TRUE"
    tty: true
    stdin_open: true
    restart: unless-stopped
    volumes:
      # attach a directory relative to the directory containing this compose file
      - ./data:/data

EOF

ask_run "Access to minecraft => http://${localhost}:${PORT}"
