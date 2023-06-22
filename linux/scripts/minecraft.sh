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

header "minecraft"

DATA_DIR=$(ask "Path for data default(./app/Minecraft)" "./app/Minecraft")
PORT=$(ask "HTTP port default(25565)" "25565")

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./data

echo "Create ${DATA_DIR}/docker-compose.yml"

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

echo "Access to minecraft => http://${localhost}:${PORT}"
