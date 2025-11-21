#!/bin/bash

tools_bin_dir="$HOME/.local/bin/yg/"
tools_share_dir="$HOME/.local/share/yg/"

function yg_list {
    if [ ! -d $tools_share_dir ]; then
	echo "$tools_share_dir does NOT exist"
	echo "So you don't have any ygtool in your local directory"
	return 1
   elif [ ! -x $tools_share_dir ] || [ ! -r $tools_share_dir ]; then
	echo "It seems that you have NO permission to access the $tools_share_dir"
	return 2
   else
	local list=$(ls $tools_share_dir)
	if [ -z "$list" ]; then
   	    echo "Don't have any ygtool !!!"
	    return 3
	fi

	echo "The list of ygtool:"
        for tool in $list; do
	    echo "$tool"
	done
   fi
   return 0
}

yg_list
