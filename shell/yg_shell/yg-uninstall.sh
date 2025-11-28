#!/bin/bash

# Usage: yg.sh tool_dir

tools_bin_dir="$HOME/.local/bin/yg/"
tools_share_dir="$HOME/.local/share/yg/"

function yg_uninstall {
    local tool_name="$1"
    local script_dir="$tools_share_dir/$tool_name/"
    local link_dir="$tools_bin_dir/"
    local csv_file="$script_dir/yg.csv"

    if [ ! -w $tools_share_dir ]; then 
	echo "It seems that you have NO permission to write the $tools_share_dir"
	return 3
    elif [ !  -w $tools_bin_dir ]; then 
	echo "It seems that you have NO permission to write the $tools_bin_dir"
	return 4
    elif [ ! -f $csv_file ] || [ ! -r $csv_file ]; then
	echo "Please create a csv file to specify how to install scripts"
	return 5
    else
	local script link
	while IFS=',' read -r script link; do
	    rm "$link_dir/$link"
	    echo -e "$link \t->\t $script \t (delete)"
	done < "$csv_file"

	rm -r "$script_dir"
    fi
    
    # echo "Installed $(basename $tool_dir) successfully"
    return 0
}

if [ ! $# -eq 1 ]; then
    echo "Just one parameter"
    exit 6
else
    yg_uninstall $1
    exit $?
fi

