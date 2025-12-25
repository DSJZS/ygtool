#!/bin/bash

# 具体的用法参考 help_me 函数( 或者直接运行 -h 选项 )
# 建议使用 alias 命令取别名( 可以配合 Git 使用 )

# 这里远程仓库和分支可以根据个人喜好修改
GIT_REPO="repo_ssh"
GIT_BRANCH="main"

BLOG_NAME=""
TEXT_EDITOR=""
BLOG_ROOT_DIR_PATH=""

MODE="NONE"
OPTION_FLAG=""

ALL_YES='NO'

function err_log {
    echo "[ERROR]: $1"
    exit 0
}

function yes_or_no {
    if [ $ALL_YES = 'YES' ]; then
        return 0
    fi

    read -p "[Question] $1 | yes or no >: " user_input
    case "$user_input" in
        y|Y|yes|Yes|yEs|yeS|YEs|YeS|yES|YES)                                                                                       
            return 0;;
        *)   
            return 1;;
    esac    
}

function set_mode {
    if [ $MODE = "NONE" ]; then
        MODE="$1"
    else
        err_log "不能同时设置多个模式，请只设置一个模式"
    fi
}

function edit_blog {
    if [ -n "$TEXT_EDITOR" ]; then
        if ! ls "content/post/$BLOG_NAME/index.zh-cn.md" &> /dev/null; then
            err_log "不存在该博客，真的创建了吗？"
        fi

        echo "开始编辑博客 $BLOG_NAME ......"
        "$TEXT_EDITOR" "content/post/$BLOG_NAME/index.zh-cn.md"

        if [ $? -ne 0 ]; then
            err_log "编辑博客 $BLOG_NAME 失败。原因如上，脚本中止!"
        fi

        return 0
    else
        return 1
    fi
}

function new_blog {
    hugo new "content/post/$BLOG_NAME/index.zh-cn.md" 

    if [ $? -ne 0 ]; then
        echo "[Warning]:创建博客 $BLOG_NAME 失败。原因如上，创建中止!"
        if ! yes_or_no "是否转为重新编辑该博客?"; then
            err_log "创建博客 $BLOG_NAME 失败!"
        fi
    else
        echo "创建博客 $BLOG_NAME 成功!"
    fi

    edit_blog
}

function delete_blog {
    if ! yes_or_no "真的决定删除了吗?"; then
        return 0
    fi

    # 需要安装 trash-cli 工具
    if which 'trash-put' &> /dev/null; then
        trash-put "content/post/$BLOG_NAME/"
    # 使用不安全的命令 rm
    else
        echo "[WARNING]: 正在使用不安全的 rm 命令删除，注意删除的内容是否正确"
        echo "[VERBOSE]: 建议安装 trash-cli 工具"
        rm -r "content/post/$BLOG_NAME/"
    fi

    if [ $? -ne 0 ]; then
        err_log "删除博客 $BLOG_NAME 失败，原因如上，脚本中止!"
    else
        echo "删除博客成功 $BLOG_NAME!"
    fi
}

function help_me {
cat << EOF
Hugo博客管理脚本

该脚本用于管理Hugo博客的完整工作流，支持本地内容创作和Git推送部署。

基本语法:
    hugo_blog [选项]

选项说明:
    -d <博客名称>    删除指定名称的博客文章
                     注意：如果系统安装了trash-cli工具，会使用trash-put安全删除；
                     否则使用rm命令直接删除，请谨慎操作。
    
    -e <编辑器命令>  设置用于编辑博客的文本编辑器
                     例如：-e vim, -e nano, -e code
                     如果未指定，编辑功能将不可用。
    
    -g               将博客更改推送到Git远程仓库
                     执行: git add . → git commit → git push
                     使用前请确保已正确配置GIT_REPO和GIT_BRANCH变量。
    
    -h               显示此帮助文档
    
    -l               列出content/post/目录下的所有博客文章
    
    -n <博客名称>    创建新的博客文章，并打开编辑器进行编辑
                     这会执行: hugo new content/post/<博客名称>/index.zh-cn.md
    
    -p <目录路径>    指定Hugo博客项目的根目录路径（必需参数）
                     例如：-p ~/my-hugo-site/
    
    -r <博客名称>    阅读指定博客文章的内容
    
    -t               打开开发服务器以查看网站

    -w <博客名称>    重新编辑（重写）已存在的博客文章

    -y               Yes or No 时默认为 Yes

使用示例:
    1. 完整工作流：创建博客并推送到Git仓库
       hugo_blog -p ~/my-hugo-site/ -n "我的技术分享" -e vim
       hugo_blog -p ~/my-hugo-site/ -g
    
    2. 快速创建并推送新博客
       hugo_blog -p ~/my-hugo-site/ -n "今日更新" -e nano
       # 编辑完成后，直接推送
       hugo_blog -p ~/my-hugo-site/ -g
    
    3. 仅推送Git更改（不编辑内容）
       hugo_blog -p ~/my-hugo-site/ -g
    
    4. 编辑已存在的博客并推送
       hugo_blog -p ~/my-hugo-site/ -w "旧文章优化" -e code
       hugo_blog -p ~/my-hugo-site/ -g
    
    5. 列出所有博客
       hugo_blog -p ~/my-hugo-site/ -l
    
    6. 阅读博客内容
       hugo_blog -p ~/my-hugo-site/ -r "我的技术分享"
    
    7. 删除博客并同步到Git
       hugo_blog -p ~/my-hugo-site/ -d "过时内容"
       hugo_blog -p ~/my-hugo-site/ -g

脚本配置提示（请编辑脚本开头的变量）:
    • GIT_REPO="repo_ssh"    # 远程仓库别名（如origin）或SSH地址
    • GIT_BRANCH="main"      # 推送的目标分支

重要提示:
    • -p 选项是必需的，必须指定Hugo博客项目的根目录
    • -g 选项会执行完整Git流程：添加所有更改 → 交互式提交 → 推送到远程
    • 脚本会自动切换到指定目录执行操作，完成后返回原目录
    • Git推送会打开默认编辑器编辑提交信息，请准备好合适的提交消息

EOF
}

function read_blog {
    if ! ls "content/post/$BLOG_NAME/index.zh-cn.md" &> /dev/null; then
        err_log "不存在该博客，真的创建了吗？"
    else
        cat "content/post/$BLOG_NAME/index.zh-cn.md"
    fi
}

function list_blog {
    ls "content/post/"
}

function git_push_blogs {
    git add .

    # 这里默认会打开文本编辑器编辑 Commit Log
    git commit
    
    git push "$GIT_REPO" "$GIT_BRANCH"

    if [ $? -ne 0 ]; then
        err_log "Git推送博客失败。原因如上，脚本中止!"
    else
        echo "Git推送博客成功!"
    fi
}

function build_drafts {
    # hugo server --buildDrafts
    hugo server -D
}

function run_script_func {
    cd "$BLOG_ROOT_DIR_PATH"
    
    "$1"

    # 防止有人直接 . ./hugo_blog.sh x y z
    cd - > /dev/null
}

# 处理选项与命令行参数
set -- $(getopt d:e:ghln:p:r:tw:y "$@")
# echo "$@"
while [ -n "$1" ]; do
    case "$1" in
        #  "DELETE 删除博客"
        -d) 
            OPTION_FLAG='DELETE'
            set_mode 'DELETE'
            BLOG_NAME="$2"
            shift
            ;;
        #  "Text Editor 文本编辑器"
        -e) 
            OPTION_FLAG='EDIT'
            if which "$2" &> /dev/null; then
                TEXT_EDITOR="$2"
                shift
            else
                err_log "没有找到你指定的文本编辑器 $2"
            fi
            ;;
        #  "Git Push Git推送博客"
        -g)
            OPTION_FLAG='GIT'
            set_mode 'GIT'
            ;;
        #  "Help 帮助文档"
        -h)
            OPTION_FLAG='HELP'
            help_me
            exit 0
            ;;
        #  "List 列出所有博客"
        -l)
            OPTION_FLAG='LIST'
            set_mode 'LIST'
            ;;
        #  "New 创建博客"
        -n) 
            OPTION_FLAG='NEW'
            set_mode 'NEW'
            BLOG_NAME="$2"
            shift
            ;;
        #  "Blog Root Directory Path 文本根目录路径"
        -p) 
            OPTION_FLAG='PATH'
            if ls "$2" &> /dev/null; then
                BLOG_ROOT_DIR_PATH="$2/"
                shift
            else
                err_log "指定的文本根目录路径 $2 不存在"
            fi
            ;;
        #  "Read 读博客"
        -r)
            OPTION_FLAG='READ'
            set_mode 'READ'
            BLOG_NAME="$2"
            shift
            ;;
        #  "Test / buildDrafts / Develop 开启测试服务器"
        -t)
            OPTION_FLAG='TEST'
            set_mode 'TEST'
            ;;
        #  "(Re)write 重写博客 "
        -w)
            OPTION_FLAG='WRITE'
            set_mode 'WRITE'
            BLOG_NAME="$2"
            shift
            ;;
        #  "All YES 默认为Yes "
        -y)
            ALL_YES='YES'
            ;;
        --) shift; break;;
        *)  
            if [ $OPTION_FLAG = "NEW" ] || [ $OPTION_FLAG = "DELETE" ] || [ $OPTION_FLAG = "WRITE" ] || [ $OPTION_FLAG = "READ" ]; then
                BLOG_NAME="$BLOG_NAME $1"
            else
                err_log "未知的选项!!!"
            fi
            ;;
    esac
    shift
done

if [ -z "$BLOG_ROOT_DIR_PATH" ]; then
    err_log "必须指定文本根目录路径"
elif [ $MODE = "NEW" ]; then
    run_script_func 'new_blog'
elif [ $MODE = "DELETE" ]; then
    run_script_func 'delete_blog'
elif [ $MODE = "WRITE" ]; then
    run_script_func 'edit_blog'
elif [ $MODE = "LIST" ]; then
    run_script_func 'list_blog'
elif [ $MODE = "READ" ]; then
    run_script_func 'read_blog'
elif [ $MODE = "GIT" ]; then
    run_script_func 'git_push_blogs'
elif [ $MODE = 'TEST' ]; then
    run_script_func 'build_drafts'
else
    err_log "必须指定模式为创建博客、删除博客或者(重)写博客，并添加上博客的名称"
fi
# cd "$BLOG_ROOT_DIR_PATH"

exit 0
