#!/bin/bash

tool_name="eng_dict"


prefix="."

if [ ! $(basename $0) = "$tool_name.sh" ]; then
   	tool_share_dir="$HOME/.local/share/yg/$tool_name"
	prefix=$tool_share_dir
 fi

DICT_FILE="$prefix/EnWords.txt"

if [ $# -eq 0 ]; then
    echo "Usgae: $tool_name word1 word2 ... wordn"
	exit 1
fi

word_cnt=1

while [ -n "$1" ]; do
    echo "$word_cnt: $1"

	word_csv=$(cat $DICT_FILE | grep "\"$1\"")
	if [ $? -eq 0 ]; then
		echo "$word_csv" | sed 's/^"[^"]*","\([^"]*\)".*$/\1/'
		echo
    else
		echo "词典没有记录这个单词"
		echo
    fi

	word_cnt=$[ $word_cnt + 1 ]
	shift
done

exit 0
