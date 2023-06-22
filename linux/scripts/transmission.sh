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

header "Transmission"

DATA_DIR=$(ask "Path for data default(./app/Transmission)" "./app/Transmission")
PORT=$(ask "HTTP port default(9091)" "9091")
PORT_2=$(ask "HTTP port 2 default(51413)" "51413")
PORT_UDP=$(ask "UDP port default(51413)" "51413")
USER=$(ask "User name default(transmission)" "transmission")
PASS=$(ask "User pass default(transmission)" "transmission")
PUID=$(ask "User PUID default(1000)" "1000")
PGID=$(ask "User PGID default(1000)" "1000")
TRANSMISSION_WEB_HOME=$(ask "Transmission UI")

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}"/ || exit
mkdir -p ./data
mkdir -p ./downloads
mkdir -p ./watch

echo "Create ${DATA_DIR}/docker-compose.yml"

cat <<EOF >./docker-compose.yml
version: '3.5'
services:
  transmission:
    image: lscr.io/linuxserver/transmission
    container_name: transmission
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TRANSMISSION_WEB_HOME=${TRANSMISSION_WEB_HOME}
      - USER=${USER}
      - PASS=${PASS}
      # - WHITELIST= #optional
      # - PEERPORT= #optional
      # - HOST_WHITELIST= #optional
    volumes:
      - ./data:/config
      - ./downloads:/downloads
      - ./watch/folder:/watch
      - /etc/localtime:/etc/localtime:ro
    ports:
      - ${localhost}:${PORT}:9091
      - ${localhost}:${PORT_2}:51413
      - ${localhost}:${PORT_UDP}:51413/udp
    restart: unless-stopped

EOF

echo "Access to transmission => http://${localhost}:${PORT}"
