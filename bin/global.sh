#!/usr/bin/env bash

function get_logs_path {
    if [ -d "$PWD/logs" ]; then
        echo "$PWD/logs/init.log"
    else
        echo "../../logs/init.log"
    fi

}

function clean_logs_file {
    path_log=$(get_logs_path)
    echo "" >"$path_log"
}

function loop {
    spinner="/|\\-/|\\-"
    while :; do
        for i in $(seq 0 7); do
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 0.5
        done
    done
}

function action {
    path_log="$(get_logs_path)"
    cmd="$1"
    section "$cmd"
    loop &
    SPIN_PID=$!
    {
        echo
        echo "######  $cmd ######"
        echo
    } >>"$path_log"

    eval "$cmd" &>>"$path_log"
    kill $SPIN_PID
    wait $SPIN_PID 2>/dev/null
    echo -n " "
    echo " "
}

function clean {
    clear
}

function get_ip {
    localhost=$(hostname -I | cut -d ' ' -f1)
    echo "$localhost"
}

function get_locale {
    locale=$(locale | grep -i LANG= | cut -d '=' -f2 | cut -d '.' -f1)
    echo "$locale"
}

function get_distrib {
    distrib=$(lsb_release -a | grep -i 'Distributor ID:' | cut -d ':' -f2 | tr -d '[[:blank:]]' | tr '[:upper:]' '[:lower:]')
    echo "$distrib"
}

function header {
    printf "=%.0s" $(seq 1 "$(expr "$(tput cols)" / 4)")
    printf " %s " "$(echo "$1" | tr '[:lower:]' '[:upper:]')"
    printf "=%.0s" $(seq 1 "$(expr "$(tput cols)" / 4)")
    echo " "
}

function section {
    printf "  -> %s " "$1"
}

function ask {
    read -r -p "  -> $1 : " user_res
    local res=${user_res:-"$2"}
    echo "$res"
}

function divider {
    printf '_%.0s' $(seq 1 "$(expr "$(tput cols)" / 2)")
    echo
}

function error_response {
    RED='\033[0;31m'
    NC='\033[0m'
    printf "${RED}/!\ %s /!\ ${NC} " "$1"
}

function up_container {
    action "docker compose up -d"
    for args in "$@"; do
        section "$args"
        echo
    done
}

function ask_run {
    while true; do
        echo
        response=$(ask "Run the container ? (y/n)")
        case $response in
        [yY])
            up_container "$@"
            break
            ;;
        [nN])
            break
            ;;
        *)
            error_response 'Type yY or nN'
            ;;
        esac
    done
}
