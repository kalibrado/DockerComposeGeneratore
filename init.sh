#!/usr/bin/env bash

unameOut="$(uname -s)"
case "${unameOut}" in
Linux*) bash ./linux/init.sh ;;
Darwin*) echo "Not Dev Sorry 😱" ;;
CYGWIN*) echo "Not Dev Sorry 😱" ;;
MINGW*) echo "Not Dev Sorry 😱" ;;
esac
exit 0
