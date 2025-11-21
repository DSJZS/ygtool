#!/bin/bash

set -- $(getopt -qu adfsp: $@)

# if not, only change the scripts with shebang;
# if so, change all the scripts.
add_mode='n'

# if it's 'f', read the arguments as files
# if it's 'd', read the arguments as directory
read_mode='n'

# if not, do NOT save the original files
save_mode='n'
old_file_list=""

# the path of the shell used
shell_path="/bin/sh"
user_path_flag='n'

function change_read_mode {
    if [ $read_mode = 'd' ] || [ $read_mode = 'f' ]; then
        echo "error: The read_mode can NOT be specified repeatedly"
	exit 1
    elif [ -z $1 ]; then
        echo "error: Please specify whether the read_mode is 'f' or 'd'"
	exit 2
    else
	read_mode=$1
    fi
}

# if return 0, there is shebang in the file
function is_there_shebang {
    sed -sn '1s|#!|#!|p' "$1" | grep -q .
}

function change_file_shebang {
    if [ -f $1 ]; then
        is_there_shebang "$1"
    elif [ -d $1 ]; then
	echo "skip $1, a directory"
	return 1
    fi

    if [ $? -eq 0 ]; then
        echo "change file with shebang: $1"
	
	if [ $save_mode = 'y' ]; then 
	    cat "$1" > "$1.old"
	    old_file_list="$1.old $old_file_list"
	fi
	
	sed -i "1c\
	    #!$shell_path" "$1" 
    elif [ $add_mode = 'y' ]; then
	echo "change file without shebang: $1"

        if [ $save_mode = 'y' ]; then 
	    cat "$1" > "$1.old"
            old_file_list="$1.old $old_file_list"
	fi

        sed -i "1i\
            #!$shell_path" "$1"
    fi

    return 0
}

function create_tgz_file {
    local tgz_name="backup_files.tgz"
    local save_dir=${1%/}
    local tgz_path="$save_dir/$tgz_name"

    shift
    if [ $save_mode = 'y' ]; then
	echo $old_file_list
	echo -e "\nThe following backup files are archived and compressed into $tgz_path"
	echo      "---------------------------------------------------------------------"
	tar -czvf $tgz_path $old_file_list
	if [ $? -eq 0 ]; then
	    rm $old_file_list
	fi
        echo -e   "---------------------------------------------------------------------\n"
	old_file_list=""
    fi
}

function modify_shebang {
    local arg
    # read -p "Directory name in which to store new script?" new_script_dirs

    echo -e "\nThe following files have #!$shell_path as their shebang:"
    echo      "========================================================"

    for arg in $@; do
        if [ $read_mode = 'f' ]; then
	    # echo "file: $arg"
            change_file_shebang $arg
	elif [ $read_mode = 'd'  ]; then
	    arg=${arg%/}
            # echo "directory: $arg/"
            local file
	    for file in $(realpath "$arg/*"); do
                change_file_shebang $file
	    done
            create_tgz_file "$arg"
	fi
    done

    if [ $read_mode = 'f' ]; then
	create_tgz_file "."
    fi

    echo -e "\nEnd of report"
}

while [ -n "$1" ]; do
    opt="$1"
    case "$opt" in
	-a) # echo "add_mode"
	   add_mode='y' ;;
	-f) # echo "file_mode"
	   change_read_mode 'f' ;;
	-d) # echo "directory_mode"
	   change_read_mode "d" ;;
	-s) # echo "save_mode"
	   save_mode='y' ;;
	-p) # echo "shell_path"
	   shell_path="$2"
	   user_path_flag='y'
	   shift ;;
        --) shift
            break ;;
        *) echo "unknow option: $opt" ;;
    esac
    shift
done

if [ $read_mode = 'n' ]; then
    echo "[error]: The read_mode must be specified"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "[error]: The target object must be specified"
    exit 2
fi

if [ $user_path_flag = 'n' ]; then
    echo "[warning]: You have NOT specified the path of the shell, the default path will be used"
fi

read -p "Are you sure you want to change the old shebang to '#!$shell_path' ? [y/n] >" response

if [ $response = "y" ] || [ $response = "Y" ] || [ $response = "yes" ] || [ $response = "Yes" ] || [ $response = "YES" ]; then  
    modify_shebang "$@"

    
else
    echo "Nothing happened"
fi

exit 0
