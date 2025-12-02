#!/bin/bash

# 用每天的日期作为文件的标识
today=$(date +%y%m%d)
backup_file="archive$today.tar.gz"

# 设置配置文件和备份文件的位置
file_prefix='/archive/'
config_file="$file_prefix/files_to_backup.config"
distination="$file_prefix/$backup_file"

# 检查配置文件是否存在
if [ -f $config_file ]; then
    echo
else
    echo
    echo "$config_file does NOT exist."
    echo "Backup not completed due to missing Configuration File"
    echo
    exit 1
fi

# 记录所有要备份的文件目录路径(并提醒配置文件中的错误目录配置)
file_no=1
exec 0< $config_file
read file_name
while [ $? -eq 0 ]; do
    if [ -f $file_name -o -d $file_name ]; then
        file_list="$file_list $file_name"
    else
        echo
        echo "$file_name, does NOT exist."
        echo "Obviously, I will not include it in this archive."
        echo "It is listed on line $file_no of the config file."
        echo "Continuing to build archive list..."
        echo
    fi
    file_no=$[ $file_no + 1 ]
    read file_name
done
# echo $file_list

# 检查目录列表是否为空
if [ -z "$file_list" ]; then
    echo
    echo "$config_file does NOT have any path."
    echo
    exit 1
fi

# 开始备份文件
echo "Starting archive..."
echo
tar -czf $distination $file_list 2> /dev/null
echo "Archive completed"
echo "Resulting archive file is: $distination"
echo

exit 0
