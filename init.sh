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

linux_install=$1

echo $linux_install
if [ $linux_install ]; then
    header "Update"
    apt-get update
    header "Upgrade"
    apt-get full-upgrade -y
    header "Install"
    apt-get install ca-certificates curl gnupg lsb-release -y
    distrib=$(get_distrib)
    if [ ! -f "/etc/apt/keyrings/docker.gpg" ]; then
        dockergpg=/etc/apt/keyrings/docker.gpg
        header "Prepare to install docker"
        mkdir -p /etc/apt/keyrings
        chmod 0755 /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$distrib/gpg | gpg --dearmor -o $dockergpg
        chmod a+r $dockergpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=$dockergpg] https://download.docker.com/linux/$distrib  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
        apt-get update
        apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        groupadd docker
        usermod -aG docker $USER
    fi
    header "Clean"
    apt-get autoremove -y
    apt-get autoclean -y
fi

header "Starting creation docker container"
IFS=$'\n'
for file in ./scripts/*.sh; do
    name="$(echo "$file" | cut -d '/' -f 3 | cut -d '.' -f 1)"
    while true; do
        header $name
        response=$(ask "Create container ${name} (y/n)")
        case $response in
        [yY])
            chmod +x $file
            echo "Starting script $file"
            bash "$file"
            echo
            break
            ;;
        [nN])
            break
            ;;
        *)
            echo 'Type yY or nN'
            ;;
        esac
    done
done

header "End to creation docker container"
echo "If you use a firewall don't forget to open the ports you have just defined."
