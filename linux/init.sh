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

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root." >&2
    exit 1
fi

echo "Install Docker"
curl -fsSL https://get.docker.com | bash

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
