#!/usr/bin/env bash
source "$PWD/bin/global.sh"

clean_logs_file
clean
header "Update"
action "apt-get update"
header "Upgrade"
action "apt-get full-upgrade -y"
header "Install"
action "apt-get install ca-certificates curl gnupg lsb-release -y"
distrib=$(get_distrib)
if [ ! -f "/etc/apt/keyrings/docker.gpg" ]; then
    dockergpg=/etc/apt/keyrings/docker.gpg
    header "Prepare to install docker"
    action "mkdir -p /etc/apt/keyrings"
    action "chmod 0755 /etc/apt/keyrings"
    action "curl -fsSL https://download.docker.com/linux/$distrib/gpg | gpg --dearmor -o $dockergpg"
    action "chmod a+r $dockergpg"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$dockergpg] https://download.docker.com/linux/$distrib  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
    action "apt-get update"
    action "apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y"
    action "groupadd docker"
    action "usermod -aG docker $USER"

fi

header "Clean"
action "apt-get autoremove -y"
action "apt-get autoclean -y"

header "Starting creation docker container"
IFS=$'\n'
for file in ./scripts/*.sh; do
    name="$(echo "$file" | cut -d '/' -f 3 | cut -d '.' -f 1)"
    while true; do
        response=$(ask "Create container ${name} (y/n)")
        case $response in
        [yY])
            action "chmod +x $file"
            section "Starting script $file"
            echo
            clean
            bash "$file"
            divider
            break
            ;;
        [nN])
            divider
            break
            ;;
        *)
            error_response 'Type yY or nN'
            ;;
        esac
    done
done

header "End to creation docker container"

error_response "If you use a firewall don't forget to open the ports you have just defined."
