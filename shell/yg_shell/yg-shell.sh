#!/bin/bash
 
set -- $(getopt -qu i:u:lh "$@")

function log {
    local ret=$1
    if [ $ret -ne 0 ]; then
	echo "[error] $ret"
    fi
}

while [ -n "$1" ]; do
    opt="$1"
    case "$opt" in
        -i) # echo "install" 
	   param=$2
	   ./yg-install.sh $param
	   log $?
	   shift ;;
	-l) # echo "list" 
	   ./yg-list.sh ;;
	-u) # echo "uninstall" 
	   param=$2
	   ./yg-uninstall.sh $param
	   log $?
	   shift ;;
	-h) # echo "help"
	   ./yg-help.sh ;;
	--) shift
	    break ;;
	*) echo "unknow option: $opt" ;;
    esac
    shift
done
