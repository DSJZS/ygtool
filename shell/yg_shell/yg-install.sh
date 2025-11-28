#!/bin/bash

# Usage: yg.sh tool_dir

tools_bin_dir="$HOME/.local/bin/yg/"
tools_share_dir="$HOME/.local/share/yg/"

function yg_install {
    local tool_dir="$1"
    local csv_file="$tool_dir/yg.csv"
    local tool_name="$(basename $(realpath -m $tool_dir))"
    local script_dir="$tools_share_dir/$tool_name/"
    local link_dir="$tools_bin_dir/"

    if [ ! -d $tool_dir ]; then
        echo "You should provide a directory which stores ygtool files"
        return 1
    elif [ ! -x $tool_dir ] || [ ! -r $tool_dir ]; then
	    echo "It seems that you have NO permission to read the directory of the ygtool"
        return 2
    elif [ ! -w $tools_share_dir ]; then 
	    echo "It seems that you have NO permission to write the $tools_share_dir"
	    return 3
    elif [ !  -w $tools_bin_dir ]; then 
	    echo "It seems that you have NO permission to write the $tools_bin_dir"
	    return 4
    elif [ ! -f $csv_file ] || [ ! -r $csv_file ]; then
	    echo "Please create a csv file to specify how to install scripts"
	    return 5
    else

    if [ ! -d $script_dir ]; then
        mkdir -p $script_dir
    elif [ ! -x $script_dir ] || [ ! -w $script_dir ]; then
	    echo "It seems that you have NO permission to read the directory of the $tool_name"
        return 6
	fi

	cp -r $tool_dir/* "$script_dir"
        
    # echo "$tool_dir -> $script_dir"
	# echo $csv_file

	local script link
	while IFS=',' read -r script link; do
	    ln -s  "$script_dir/$script" "$link_dir/$link" 2> /dev/null
	    if [ $? -ne 0 ]; then
		    echo -e "$link \t->\t $script \t (update)"
	    else
		    echo -e "$link \t->\t $script \t (new)"
	    fi
	done < "$csv_file"
	chmod u+x $script_dir/*.sh
    fi
    
    # echo "Installed $(basename $tool_dir) successfully"
    return 0
}

if [ ! $# -eq 1 ]; then
    echo "Just one parameter"
    exit 6
else
    yg_install $1
    exit $?
fi

