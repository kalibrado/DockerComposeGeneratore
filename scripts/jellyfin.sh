#!/usr/bin/env bash

source "$PWD/bin/global.sh"

localhost=$(get_ip)

header "Jellyfin"

DATA_DIR=$(ask "Path for data (default: ./app/Jellyfin)" "./app/Jellyfin")

create_docker_user

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./config
mkdir -p ./cache
mkdir -p ./media

# Vérification du chemin d'accès pour les données
if [[ ! -d "$DATA_DIR" ]]; then
  error_response "Data directory does not exist"
  exit 1
fi

PORT=$(ask "HTTP port (default: 8096)" "8096")
# Vérification du numéro de port
if [[ ! "$PORT" =~ ^[0-9]+$ ]]; then
  error_response "Invalid port number"
  exit 1
fi

section "Create ${DATA_DIR}/docker-compose.yml"

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

# Confirmation de la création du conteneur
while true; do
  response=$(ask "Do you want to continue and start Jellyfin? (y/n)")
  case $response in
  [yY])
    ask_run "If you need to add external media" \
      "ex: sudo mkdir ${DATA_DIR}/media/disk1" \
      "ex: sudo mount /dev/sdX ${DATA_DIR}/media/disk1" \
      "Access Jellyfin at http://${localhost}:${PORT}"
    break
    ;;
  [nN])
    divider
    exit 0
    ;;
  *)
    error_response 'Type yY or nN'
    ;;
  esac
done
