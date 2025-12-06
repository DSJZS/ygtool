#!/bin/bash
####################  定义询问用户的函数  ####################
function get_answer {

    # 变量初始化。
    unset answer
    ask_count=0

    # 没有答案时继续询问。
    while [ -z "$answer" ]; do

        # 记录当前不作答次数。
        ask_count=$((ask_count + 1))

        # 根据次数给出相应提示。
        case $ask_count in
        2)
            echo
            echo "Please answer the question."
            echo
            ;;
        3)
            echo
            echo "One last try...please answer the question."
            echo
            ;;
        4)
            echo
            echo "Since you refuse to answer the question..."
            echo "exiting program."
            echo
            # 超过三次则退出。
            exit
            ;;
        esac
        #
        # 打印询问内容。
        if [ -n "$line2" ]; then
            echo $line1
            echo -e $line2" \c"
        else
            echo -e $line1" \c"
        fi
        #
        # 设置 60 s 超时作答。
        read -t 60 answer
    done

    # 重置变量。
    unset line1
    unset line2
    #
}

####################  定义用户确认函数  ####################
function process_answer {
    # 截取字符串。（只保留第一个字符。）
    answer=$(echo $answer | cut -c1)

    case $answer in
    y | Y)
        # 如果回答的是“yes”。则什么也不做。
        ;;
    *)
        # 如果回答不是“yes”，则退出脚本。
        echo
        echo $exit_line1
        echo $exit_line2
        echo
        exit
        ;;
    esac

    # 重置变量。
    unset exit_line1
    unset exit_line2
    #
}

####################  具体的执行逻辑：  ####################
#
####################  【第一步】：获取并确认待删除的用户账户名  ####################
echo "Step #1 - Determine User Account name to Delete "
echo
line1="Please enter the username of the user "
line2="account you wish to delete from system:"
get_answer
user_account=$answer
#
# 询问是否为希望移除的用户账户。
line1="Is $user_account the user account "
line2="you wish to delete from the system? [y/n]"
get_answer
#
# 调用确认函数。（如果用户的回答不是“yes”，则退出脚本。）
exit_line1="Because the account, $user_account, is not "
exit_line1="the one you wish to delete, we are leaving the script..."
process_answer
#
# 检查是否确实是系统上的一个账户。
user_account_record=$(cat /etc/passwd | grep -w $user_account)
# 如果没有找到帐号，退出脚本。
if [ $? -eq 1 ]; then
    echo
    echo "Account, $user_account, not found. "
    echo "Leaving the script..."
    echo
    exit
fi
#
echo
echo "I found this record:"
echo $user_account_record
echo
#
line1="Is this the correct User Account? [y/n]"
get_answer
#
# 再次确认用户回答，如果不是“yes”，则退出脚本。
exit_line1="Because the account, $user_account, is not "
exit_line2="the one you wish to delete, we are leaving the script..."
process_answer
#

####################  【第二步】：查找并“杀死”该用户账户的所有进程  ####################
echo
echo "Step #2 - Find process on system belonging to user account"
echo
# 列出正在运行的用户进程。
ps -u $user_account >/dev/null
case $? in
1)
    # 退出状态码是1，表示此用户帐户没有正在运行的进程。
    echo "There are no processes for this account 
currently running."
    echo
    ;;
0)
    # 退出状态码是0，表示该用户帐户正在运行的进程。
    # 询问脚本用户是否希望“杀死”进程。
    echo "$user_account has the following process(es) running:"
    ps -u $user_account
    #
    line1="Would you like me to kill the process(es)? [y/n]"
    get_answer
    # 截取用户回答。
    answer=$(echo $answer | cut -c1)
    case $answer in
    y | Y)
        # 如果回答“yes”，则准备“杀死”进程。
        echo
        echo "Killing off process(es)..."

        # 列出用户正在运行的进程。
        command_1="ps -u $user_account --no-heading"

        # “杀死”进程的命令。
        command_3="xargs -d \\n /usr/bin/sudo /bin/kill -9"
        #
        # 收集并提取当前账户进程的PID，执行“杀死”进程操作。
        $command_1 | gawk '{print $1}' | $command_3
        #
        echo
        echo "Process(es) killed."
        ;;
    *)
        # 没有回答“yes”，则不“杀死”进程。
        echo
        echo "Will not kill process(es)."
        ;;
    esac
    ;;
esac
#

####################  【第三步】：创建该用户账户所拥有的全部文件的报告  ####################
echo
echo "Step #3 - Find files on system belonging to user account"
echo
echo "Creating a report of all files owned by $user_account."
echo
echo "It is recommended that you backup/archive these files,"
echo "and then do one of two things:"
echo " 1) Delete the files"
echo " 2) Change the files' ownership to a current user account."
echo
echo "Please wait. This may take a while..."
# 日期及文件信息。
report_date=$(date +%y%m%d)
report_file="$user_account"_Files_"$report_date".rpt
# 查找整个文件系统，准确找出属于该用户的所有文件。
find / -user $user_account >$report_file 2>/dev/null
#
echo
echo "Report is complete."
echo "Name of report: $report_file"
echo -n "Location of report: "
pwd
echo
#

####################  【第四步】：删除该用户账户  ####################
echo
echo "Step #4 - Remove user account"
echo
#
line1="Do you wish to remove $user_account's account from system? [y/n]"
get_answer
#
exit_line1="Since you do not wish to remove the user account,"
exit_line2="$user_account at this time, exiting the script..."
process_answer
# 删除用户账户。
userdel $user_account
echo
echo "User account, $user_account, has been removed"
echo
# 退出。
exit
#

