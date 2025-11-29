#!/bin/bash

# 要首先判断工具是在测试还是已经安装，以获取正确的前缀
tool_name="eng_dict"
prefix="."

if [ ! $(basename $0) = "$tool_name.sh" ]; then
   	tool_share_dir="$HOME/.local/share/yg/$tool_name"
	prefix=$tool_share_dir
 fi

DICT_FILE="$prefix/EnWords.txt"
# DICT_FILE="$prefix/test.txt"

USER_DICT_FILE="$prefix/UserWords.txt"

function look_for_words {
    local is_continuing=$1
	local last_ret=$2
	local is_ignore=$3
	local dict_file=$4
	local words=$5

    local words_csv=""

	if [ $is_ignore = "y" ]; then
	    words_csv=$(cat $dict_file | grep -i "\"$words\"")
    else
		words_csv=$(cat $dict_file | grep "\"$words\"")
    fi

	local ret=$?
	
	if [ $is_continuing = "y" ] && [ $last_ret -eq 0 ]; then
		ret=0
    fi

	echo "$words_csv"
    return $ret
}

function translate_words {
    local word_cnt=1
    local ignore=$1
	local verbose=$2
	shift 2
		
    while [ -n "$1" ]; do
        echo "$word_cnt: $1"

	    local word_csv 
		local ret=1

		if [ $verbose = 'n' ]; then
		    word_csv=$(look_for_words "y" "$ret" "$ignore" "$DICT_FILE" "$1")
		    ret=$?
		elif [ $verbose = 'y' ]; then
		    word_csv=$(look_for_words "y" "$ret" "$ignore" "$DICT_FILE" "$1")
			ret=$?
			if [ $ret -eq 1 ]; then
		        word_csv="$(look_for_words "y" "$ret" "$ignore" "$USER_DICT_FILE" "$1")"
			else
			    word_csv="$word_csv"$'\n'"$(look_for_words "y" "$ret" "$ignore" "$USER_DICT_FILE" "$1")"
			fi
			ret=$?
		fi

	    if [ $ret -eq 0 ]; then
            local en_cn=$(echo "$word_csv" | sed 's/^"\([^"]*\)","\([^"]*\)".*$/\1 \2/')

			local en_word cn_meaning
			while read en_word cn_meaning; do
		        # if [ $1 != $en_word ]; then
		        if [ $ignore = 'y' ]; then
				    echo -e "(->$en_word)"
		        fi
		        echo -ne "\t$cn_meaning" 
		        echo
		    done <<< $en_cn
        else
		    echo "词典没有记录这个单词"
		    echo
        fi

	    word_cnt=$[ $word_cnt + 1 ]
	    shift
    done
}

function help {
echo "[error]: $1"
echo
cat << EOF
a - 添加单词翻译到用户自定义单词库
d - 删除单词翻译到用户自定义单词库
t - 翻译一个或者多个单词
v - 不仅从脚本自带的单词库中读取, 也从用户自定义单词库中读取
i - 忽略大小写

adt 互相冲突, 同时只能有一个
如果有 v 或者 i 但没有 t, 默认添加 t
如果没有任何合法的选项, 默认添加 t
EOF
}

if [ $# -eq 0 ]; then
    help "请输入选项"
	exit 1
fi

set -- $(getopt -qu aditv "$@")

mode="n"
is_ignore="n"
is_verbose="n"

function modify_mode {
    if [ $mode = $1 ]; then
		: # do nothing
    elif [ $mode = "n" ] && [ $1 = "i" ]; then
		mode="t"
		is_ignore="y"
    elif [ $mode = "n" ] && [ $1 = "v" ]; then
		mode="t"
		is_verbose="y"
    elif [ $mode = "n" ]; then
		mode="$1"
    elif [ $mode = "t" ] && [ $1 = "i" ]; then
		is_ignore="y"
    elif [ $mode = "t" ] && [ $1 = "v" ]; then
		is_verbose="y"
    else
		help "选项冲突 $mode <- $1"
		exit 1
    fi
}

while [ -n "$1" ]; do
    case "$1" in
		-a) # echo "add" 
		    modify_mode "a" ;;
		-d) # echo "delete" 
		    modify_mode "d" ;;
		-t) # echo "translate" 
		    modify_mode "t" ;;
		-v) # echo "verbose" 
		    modify_mode "v" ;;
		-i) # echo "ignore" 
		    modify_mode "i" ;;
		--) shift
		    break ;;
	    *) echo "$1 不是一个合法的选项" ;;
    esac
	shift
done

case "$mode" in
    a)  # echo "add" 
		;;
    d)  # echo "delete" 
		;;
    t | n) #  echo "translate" 
		translate_words $is_ignore $is_verbose "$@" ;;
    *) echo "bug" 
       exit ;;
esac

exit 0
