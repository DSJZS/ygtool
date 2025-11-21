#!/bin/bash
 
set -- $(getopt -qu i:u:lh "$@")

function log {
    local ret=$1
    if [ $ret -ne 0 ]; then
	echo "[error] $ret"
    fi
}

prefix="."
if [ ! $(basename $0) = "yg-shell.sh" ]; then
   tool_name="yg_shell"
   tool_share_dir="$HOME/.local/share/yg/$tool_name"
   prefix=$tool_share_dir
fi

while [ -n "$1" ]; do
    opt="$1"
    case "$opt" in
        -i) # echo "install" 
	   param=$2
	   $prefix/yg-install.sh $param
	   log $?
	   shift ;;
	-l) # echo "list" 
	   $prefix/yg-list.sh ;;
	-u) # echo "uninstall" 
	   param=$2
	   $prefix/yg-uninstall.sh $param
	   log $?
	   shift ;;
	-h) # echo "help"
	   $prefix/yg-help.sh ;;
	--) shift
	    break ;;
	*) echo "unknow option: $opt" ;;
    esac
    shift
done

