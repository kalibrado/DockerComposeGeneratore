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

header "Rocket.Chat"

DATA_DIR=$(ask "Path for data default(./app/RocketChat)" "./app/RocketChat")
HTTP_PORT=$(ask "HTTP port default(3130)" "3130")
DOMAIN_NAME=$(ask "Domaine name default($localhost)" "$localhost")

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit
mkdir -p ./mongodb
mkdir -p ./uploads

echo "Create ${DATA_DIR}/docker-compose.yml"

cat <<EOF >./docker-compose.yml
version: '3.7'
services:
  mongo:
    image: docker.io/bitnami/mongodb:4.4
    container_name: mongodb-rocket-chat
    restart: unless-stopped
    volumes:
      - ./mongodb:/bitnami/mongodb
    environment:
      MONGODB_REPLICA_SET_MODE: primary
      MONGODB_REPLICA_SET_NAME: rs0
      MONGODB_PORT_NUMBER: 27017
      MONGODB_INITIAL_PRIMARY_HOST: mongodb
      MONGODB_INITIAL_PRIMARY_PORT_NUMBER: 7017
      MONGODB_ADVERTISED_HOSTNAME: mongodb
      MONGODB_ENABLE_JOURNAL: true
      ALLOW_EMPTY_PASSWORD: yes
  rocketchat:
    image: registry.rocket.chat/rocketchat/rocket.chat:4.8.1
    container_name: rocket-chat
    restart: unless-stopped
    volumes:
     - ./uploads:/app/uploads
    environment:
      MONGO_URL: "mongodb://mongodb:27017/rocketchat?replicaSet=rs0"
      MONGO_OPLOG_URL: "mongodb://mongodb:27017/local?replicaSet=rs0"
      ROOT_URL: "http://${DOMAIN_NAME}:${HTTP_PORT}"
      PORT: ${HTTP_PORT}
    depends_on:
      - mongo


EOF

echo "Access to rocket.chat => http://${DOMAIN_NAME}:${HTTP_PORT}"
