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

header "Jellyfin"

DATA_DIR=$(ask "Path for data (default: ./app/Jellyfin)" "./app/Jellyfin")
mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./config
mkdir -p ./cache
mkdir -p ./media

PORT=$(ask "HTTP port (default: 8096)" "8096")
# Vérification du numéro de port
if [[ ! "$PORT" =~ ^[0-9]+$ ]]; then
  echo "Invalid port number"
  exit 1
fi

echo "Create ${DATA_DIR}/docker-compose.yml"

cat <<EOF >./docker-compose.yml
version: '3.7'
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    ports:
      - ${localhost}:${PORT}:8096
    volumes:
      - ./config:/config
      - ./cache:/cache
      - ./media:/media
    user: docker
    restart: 'unless-stopped'
EOF

echo "If you need to add external media"
echo "ex: sudo mkdir ${DATA_DIR}/media/disk1"
echo "ex: sudo mount /dev/sdX ${DATA_DIR}/media/disk1"
echo "Access Jellyfin at http://${localhost}:${PORT}"
