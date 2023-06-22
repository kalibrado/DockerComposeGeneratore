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
function get_locale {
    locale=$(locale | grep -i LANG= | cut -d '=' -f2 | cut -d '.' -f1)
    echo "$locale"
}
# ========================================================
#  START SCRIPTS
# ========================================================
localhost=$(get_ip)
locale=$(get_locale)

header "Nextcloud"

DATA_DIR=$(ask "Path for data default(./app/Nextcloud)" "./app/Nextcloud")
HTTP=$(ask "HTTP port default(8081)" "8081")
HTTPS=$(ask "HTTPS port default(8082)" "8082")
NEXTCLOUD_ADMIN_USER=$(ask "Nextcloud admin user default(nextcloud)" "nextcloud")
NEXTCLOUD_ADMIN_PASSWORD=$(ask "Nextcloud admin pass default(nextcloud)" "nextcloud")
MYSQL_DATABASE=$(ask "Mysql database default(nextcloud)" "nextcloud")
MYSQL_USER=$(ask "Mysql username default(nextcloud)" "nextcloud")
MYSQL_PASSWORD=$(ask "Mysql user pass default(nextcloud)" "nextcloud")
MYSQL_ROOT_PASSWORD=$(ask "Mysql root password default(nextcloud)" "nextcloud")
PHP_UPLOAD_LIMIT=$(ask "PHP memory limit default(512M)" "512M")
PHP_MEMORY_LIMIT=$(ask "PHP upload limit default(1G)" "1G")

DOMAIN_NAME="$localhost"

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}"/ || exit
mkdir -p ./data
mkdir -p ./config

echo "OPcache config optimal"
cat <<EOF >./php-opcache.ini
    opcache.enable=1
    opcache.enable_cli=1
    opcache.interned_strings_buffer=32
    opcache.max_accelerated_files=10000
    opcache.memory_consumption=1024
    opcache.save_comments=1
    opcache.revalidate_freq=0
    opcache.jit=1255
    opcache.jit_buffer_size = 128M
EOF

echo "Create script for optimisation nextcloud in ${DATA_DIR}/nextcloud_opti_conf.sh"
cat <<EOF >./nextcloud_opti_conf.sh
#!/usr/bin/env bash
function occ {
  docker exec -it -u www-data nextcloud-app php /var/www/html/occ $*
}
echo "Set cron job"
occ background:cron
crontab -l >crontab_new
section "*/2 * * * * docker exec -it -u www-data nextcloud-app php -f /var/www/html/cron.php" >>crontab_new
crontab crontab_new
rm crontab_new

# Mail
echo "Set mail for Nextcoud"
read -r -p "SMTP mode : " smtp
occ config:system:set mail_smtpmode --value="$smtp"
read -r -p "SMTP send mode : " mail_sendmailmode
occ config:system:set mail_sendmailmode --value="$mail_sendmailmode"
read -r -p "Adresse mail without @ : " mail_from_address
occ config:system:set mail_from_address --value="$mail_from_address"
occ config:system:set mail_smtpname --value="$mail_from_address"
read -r -p "Password mail : " mail_smtppassword
occ config:system:set mail_smtppassword --value="$mail_smtppassword"
read -r -p "Domain mail ex: (gmail.com, outlook.com, ...) : " mail_domain
occ config:system:set mail_domain --value="$mail_domain"
read -r -p "Smtp host mail: " mail_smtphost
occ config:system:set mail_smtphost --value="$mail_smtphost"
read -r -p "Smtp port mail: " mail_smtpport
occ config:system:set mail_smtpport --value="$mail_smtpport"
occ config:system:set mail_smtpauth --value="1"
read -r -p "Smtp secure mail (ssl,tls,startssl) : " mail_smtpsecure
occ config:system:set mail_smtpsecure --value="$mail_smtpsecure"

# Locale
echo "Set locle to $locale"
occ config:system:set default_phone_region --value="${locale}"
occ config:system:set default_language --value="${locale}"
occ config:system:set force_language --value="${locale}"

# Security
echo "set security"
occ config:system:set auth.bruteforce.protection.enabled --value="true",
occ app:install files_antivirus
occ app:enable files_antivirus
occ config:app:set files_antivirus av_mode --value="socket"
occ config:app:set files_antivirus av_host --value="clamav"
occ config:app:set files_antivirus av_port --value="3310"
occ config:app:set files_antivirus av_max_file_size --value="-1"
occ config:app:set files_antivirus av_stream_max_length --value="10485760"
occ config:app:set files_antivirus av_background_scan --value="on"

# Preview
echo "Set preview"
occ config:system:set enabledPreviewProviders 0 --value="OC\\Preview\\Imaginary"
occ config:system:set enabledPreviewProviders 1 --value="OC\\Preview\\MP3"
occ config:system:set enabledPreviewProviders 2 --value="OC\\Preview\\JPEG"
occ config:system:set enabledPreviewProviders 3 --value="OC\\Preview\\PNG"
occ config:system:set enabledPreviewProviders 4 --value="OC\\Preview\\GIF"
occ config:system:set enabledPreviewProviders 5 --value="OC\\Preview\\TXT"
occ config:system:set enabledPreviewProviders 6 --value="OC\\Preview\\MarkDown"
occ config:system:set enabledPreviewProviders 7 --value="OC\\Preview\\OpenDocument"
occ config:system:set enabledPreviewProviders 8 --value="OC\\Preview\\Krita"
occ config:system:set preview_imaginary_url --value="http://${localhost}:9000"
occ app:install previewgenerator
occ app:enable previewgenerator
occ preview:pre-generate
occ preview:generate-all -vvv
EOF

echo "Create ${DATA_DIR}/docker-compose.yml"
cat <<EOF >./docker-compose.yml
version: '3.7'
services:
  # MariaDB Database
  db:
    image: mariadb
    container_name: nextcloud-mariadb
    networks:
      - nextcloud_network
    volumes:
      - db:/var/lib/mysql
      - /etc/localtime:/etc/localtime:ro
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
    restart: unless-stopped

  # Clamav Antivirus
  clamav:
    image: "mkodockx/docker-clamav:alpine"
    container_name: nextcloud-clamav
    networks:
      - nextcloud_network
    restart: unless-stopped

  # Redis
  redis:
    image: redis
    container_name: nextcloud-redis
    networks:
      - nextcloud_network
    volumes:
      - /etc/localtime:/etc/localtime:ro

  # Imaginary preview generator
  imaginary:
    image: nextcloud/aio-imaginary:latest
    container_name: nextcloud-imaginary
    environment:
      - PORT=9000
    networks:
      - nextcloud_network
    ports:
      - ${localhost}:9000:9000
    command: -concurrency 50 -enable-url-source -return-size –cap-add=sys_nice
    restart: unless-stopped



EOF

function create_reverse_proxy {
  LETSENCRYPT_EMAIL=$(ask "let's encrypt email")
  DOMAIN_NAME=$(ask "Domaine name")

  mkdir -p ./proxy

  cat <<EOF >>./docker-compose.yml
  proxy:
    image: jwilder/nginx-proxy:alpine
    labels:
      - "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true"
    container_name: nextcloud-proxy
    networks:
      - nextcloud_network
    ports:
      - ${localhost}:${HTTP}:80
      - ${localhost}:${HTTPS}:443
    volumes:
      - ./proxy/conf.d:/etc/nginx/conf.d:rw
      - ./proxy/vhost.d:/etc/nginx/vhost.d:rw
      - ./proxy/html:/usr/share/nginx/html:rw
      - ./proxy/certs:/etc/nginx/certs:ro
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro
    restart: unless-stopped
  # Lets encrypt
  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: nextcloud-letsencrypt
    depends_on:
      - proxy
    networks:
      - nextcloud_network
    volumes:
      - ./proxy/certs:/etc/nginx/certs:rw
      - ./proxy/vhost.d:/etc/nginx/vhost.d:rw
      - ./proxy/html:/usr/share/nginx/html:rw
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped

  # NextCloud
  app:
    image: nextcloud
    container_name: nextcloud-app
    networks:
      - nextcloud_network
    depends_on:
      - letsencrypt
      - imaginary
      - proxy
      - redis
      - db
    volumes:
      - nextcloud:/var/www/html
      - ./config:/var/www/html/config
      - ./custom_apps:/var/www/html/custom_apps
      - ./data:/var/www/html/data
      - ./themes:/var/www/html/themes
      - /etc/localtime:/etc/localtime:ro
    environment:
      - OVERWRITEPROTOCOL=https
      - TRUSTED_PROXIES=${DOMAIN_NAME}
      - VIRTUAL_HOST=${DOMAIN_NAME}
      - LETSENCRYPT_HOST=${DOMAIN_NAME}
      - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
      - NEXTCLOUD_TRUSTED_DOMAINS=${DOMAIN_NAME}
      - NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER}
      - NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}
      - PHP_UPLOAD_LIMIT=${PHP_UPLOAD_LIMIT}
      - PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_HOST=db
      - REDIS_HOST=redis
    restart: unless-stopped

networks:
  nextcloud_network:
volumes:
  db:
  nextcloud:
EOF
  echo "Access to nextcloud => https://${DOMAIN_NAME}:${HTTPS}"
  echo  "If you need optimisation for nextcloud use this commande ${DATA_DIR}/nextcloud_opti_conf.sh"
}

function create {
  echo "Create ${DATA_DIR}/docker-compose.yml"

  cat <<EOF >>./docker-compose.yml
  # NextCloud
  app:
    image: nextcloud
    container_name: nextcloud-app
    networks:
      - nextcloud_network
    depends_on:
      - imaginary
      - redis
      - db
    ports:
      - ${localhost}:${HTTP}:80
      - ${localhost}:${HTTPS}:443
    volumes:
      - nextcloud:/var/www/html
      - ./config:/var/www/html/config
      - ./custom_apps:/var/www/html/custom_apps
      - ./data:/var/www/html/data
      - ./themes:/var/www/html/themes
      - /etc/localtime:/etc/localtime:ro
    environment:
      - PHP_UPLOAD_LIMIT=${PHP_UPLOAD_LIMIT}
      - PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}
      - NEXTCLOUD_TRUSTED_DOMAINS=${DOMAIN_NAME}
      - NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}
      - NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_HOST=db
      - REDIS_HOST=redis
    restart: unless-stopped

networks:
  nextcloud_network:
volumes:
  db:
  nextcloud:
EOF
  echo "Access to nextcloud => http://${DOMAIN_NAME}:${HTTP}"
  echo "If you need optimisation for nextcloud use this commande ${DATA_DIR}/nextcloud_opti_conf.sh"

}

while true; do
  docker network create --driver bridge nextcloud
  response=$(ask "Use reverse proxy and let's encrypt for auto generate ssl certificat (y/n)")
  case $response in
  [yY])
    create_reverse_proxy
    break
    ;;
  [nN])
    create
    break
    ;;
  *)
    error_response 'Type yY or nN'
    ;;
  esac
done
