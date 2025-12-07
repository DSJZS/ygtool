#!/bin/bash

set -- $(getopt -qu n:p:h "$@")

SHELL_PATH="/bin/bash"

function help {
echo "选项:"
echo "-p,  指定脚本shebang的路径"
echo "-n,  指定脚本shell的种类, 该脚本自动获取路径并写到shebang"
echo "-h,  获取帮助"
echo
echo "注意:"
echo "1. 如果不使用选项 -p 和 -n, shebang默认用 #!/bin/bash "
echo '2. -n 选项只支持识别 "bash" 和 "zsh"'
}

while [ -n "$1" ]; do
    opt="$1"
    case "$opt" in
        -p) # echo "path" 
            SHELL_PATH=$2
            shift ;;
        -n) # echo "name"
            if [ $2 = "bash" ]; then
                SHELL_PATH="/bin/bash"
            elif [ $2 = "zsh" ]; then
                SHELL_PATH="/bin/zsh"
            fi
            shift ;;
        -h) # echo "help"
            help
            exit 0 ;;
        --) shift
            break ;;
        *) echo "unknow option: $opt" ;;
    esac
    shift
done

echo "创建以下空脚本, 并设置他们的shebang 为 #!$SHELL_PATH "
count=1
while [ -n "$1" ]; do
    touch "$1"
    if [ $? -eq 0 ]; then
        echo "$SHELL_PATH" >> "$1"
        chmod u+x "$1"
        echo "$count: $1"
        count=$[ $count + 1 ]
    fi
    shift
done
echo "创建完毕!!!"
