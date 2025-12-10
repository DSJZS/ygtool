#!/bin/bash

# 一些固定的(配置)配置
TOOL_NAME="c_project"
TOOL_SHARE_DIR="$HOME/.local/share/yg/$TOOL_NAME"
# 判断是否为测试环境
if [ ! $(basename $0) = "c_project.sh" ]; then
    CONFIG_DIR=$TOOL_SHARE_DIR
else
    CONFIG_DIR="$(dirname $0)/"
fi
MACRO_NORMAL_HEAD="\*\*"
MACRO_NORMAL_RAIL="\*\*"
MACRO_UPPER_HEAD="\*U"
MACRO_UPPER_RAIL="U\*"
MACRO_LOWER_HEAD="\*L"
MACRO_LOWER_RAIL="L\*"
PROJECT_NAME_MACRO="project_name_replace"
EXE_NAME_MACRO="exe_name_replace"
MODULE_NAME_MACRO="module_name_replace"

# 选项判断
IS_CREATE_PROJECT=false
IS_CREATE_ADDITIONAL_GIT=false
IS_BUILD_PROJECT=false
IS_RUN_EXECUTE=false
IS_NO_OUTPUT=false
IS_CREATE_MODULE=false

# 帮助信息
function help {
    echo "用法: $TOOL_NAME [选项] <参数...>"
    echo
    echo "选项:"
    echo "  -b <目录...>    构建指定目录下的C项目(目录下必须包含CMakeLists.txt)"
    echo "  -c <目录...>    创建新的C项目, 位置为指定目录(项目默认与末级目录同名)"
    # echo "  -e <名字>     创建新的C项目时指定可执行文件的名字 (暂未实现)"
    echo "  -g              创建新的C项目时, 额外初始化git"
    echo "  -h              显示此帮助信息(运行此选项会忽略其他所有选项)"
    echo "  -m <名字>       创建一个空的项目模块(存放于项目的src目录下) (暂未实现)"
    echo "  -n              不输出任何 -b -c -r 选项的信息(错误任会显示)"
    # echo "  -p            创建新的C项目时指定项目的名字 (暂未实现)"
    echo "  -r <目录...>     运行指定目录下C项目的可执行文件(目录/bin/项目名)"
    echo "示例:"
    echo "  $TOOL_NAME -c ./my_c_project"
    echo "  $TOOL_NAME -br ./my_c_project"
    echo "  $TOOL_NAME -gcbr ./my_c_project"
    echo "  $TOOL_NAME -m ./my_c_project my_c_module_name"
    echo "注意:"
    echo "  创建项目、编译项目、执行项目可执行文件可以连续进行,"
    echo "  但是它们均与创建模块选项冲突，冲突时默认只创建模块，忽略 -b -c -r 选项。"
    echo "  创建模块选项一次性只能针对一个项目创建一个模块。 "
    echo
    return 0
}
# 错误处理函数
function error {
    local error_message="$1"
    echo "[ERROR]: $error_message"
    exit 1
}
# 处理路径, 使其更美观
function make_path_pretty {
    local raw_path="$1"
    local pretty_path=$(echo "$raw_path" | sed 's|///*|/|g')
    echo "$pretty_path"
}
# 获取项目名称
function get_project_name {
    local project_dir="$1/"
    if [ $(basename $project_dir) = "." ]; then
        local project_name=$(basename "$(pwd)")
    else
        local project_name=$(basename "$project_dir")
    fi
    echo "$project_name"
}
# 解析宏定义
function deal_macro {
    local file_path="$1"
    local macro_key="$2"
    local macro_value="$3"
    local macro_value_upper="$(echo "$macro_value" | tr '[:lower:]' '[:upper:]')"
    local macro_value_lower="$(echo "$macro_value" | tr '[:upper:]' '[:lower:]')"

    sed -i "{   s/$MACRO_NORMAL_HEAD $macro_key $MACRO_NORMAL_RAIL/$macro_value/g
                s/$MACRO_UPPER_HEAD $macro_key $MACRO_UPPER_RAIL/$macro_value_upper/g
                s/$MACRO_LOWER_HEAD $macro_key $MACRO_LOWER_RAIL/$macro_value_lower/g
            }" "$file_path"
}
# 删除冲突文件或目录, 由于涉及 rm 命令，故小心使用，避免删除重要文件
function remove_conflict {
    local target_path="$1"
    local message="$2"
    read -p "$message 是否删除(所有的)冲突文件? (y/n): " user_input
    case "$user_input" in
        y|Y|yes|Yes|yEs|yeS|YEs|YeS|yES|YES)
            echo "正在删除: $(make_path_pretty $target_path)"
            rm -rf "$target_path"
            return $?;;
        *)
            return 1;;
    esac
}
# 模拟tree命令
function my_tree {
    local indent="${2:-}"
    local item
    
    for item in "$1"/*; do
        [ -e "$item" ] || continue  # 跳过不存在的文件
        
        # 获取文件名（不含路径）
        local name=$(basename "$item")
        
        # 打印当前项（目录或文件）
        echo "${indent}├── $name"
        
        # 如果是目录，递归处理
        if [ -d "$item" ]; then
            my_tree "$item" "${indent}│   "
        fi
    done
}
# 创建新项目模板文件
function create_new_project_template_file {
    local project_dir="$1/"
    local project_name="$2"
    local exe_name="$3"
    local create_git_flag="$4"

    local template_dir="$CONFIG_DIR/text_template/"

    local path filename
    for template_filename in $(ls "$template_dir"); do
        
        read -r path filename <<< "$(echo "$template_filename" | sed -n 's|\(.*\)_\(.*\)_template.txt|\1 \2|p')"
        
        if [ $path = "root" ]; then
            path="$project_dir/"
        else
            path="$project_dir/$path/"
        fi
        
        if [ -n "$filename" ]; then
            mkdir -p "$path"
            cat < "$template_dir/$template_filename" > "$path/$filename"
            deal_macro "$path/$filename" "$PROJECT_NAME_MACRO" "$project_name"
            deal_macro "$path/$filename" "$EXE_NAME_MACRO" "$exe_name"
        fi
    done

    if [ $create_git_flag = true ]; then
        echo "正在初始化git仓库(会自动将主分支命名为main并进行初始化提交)..."
        cat < "$template_dir/._.gitignore_template.txt" > "$project_dir/.gitignore"
        cd "$project_dir"
        git init
        # 根据个人喜好，这里我修改了分支名并进行了一个初始化提交，可以根据需要修改或删除
        git branch -m main
        git add .
        git commit -m "Initial commit"
        cd - > /dev/null
        echo "git仓库(包含忽略文件)初始化完成."
    fi

    return 0
}
# 创建新模块模板文件
function create_new_module_template_file {
    local module_dir="$1/"
    local module_name="$2"
    local project_include_dir="$3/"

    local module_include_dir="$module_dir/include/"
    local template_dir="$CONFIG_DIR/text_template/"

    mkdir -p "$module_dir/" "$project_include_dir" "$module_include_dir"
    cat < "$template_dir/.module_CMakeLists.txt_template.txt" > "$module_dir/CMakeLists.txt"
    cat < "$template_dir/.module_source_template.txt" > "$module_dir/$module_name.c"
    cat < "$template_dir/.module_header_template.txt" > "$project_include_dir/$module_name.h"
    # cat < "$template_dir/.module_private_header_template.txt" > "$module_include_dir/$module_name\_private.h"
    deal_macro "$module_dir/CMakeLists.txt" "$MODULE_NAME_MACRO" "$module_name"
    deal_macro "$module_dir/$module_name.c" "$MODULE_NAME_MACRO" "$module_name"
    deal_macro "$project_include_dir/$module_name.h" "$MODULE_NAME_MACRO" "$module_name"
    # deal_macro "$module_include_dir/$module_name\_private.h" "$module_name"

    return 0
}
# 创建模块
function create_module {
    local project_dir="$1/"
    local module_name="$2"
    local src_dir="$project_dir/src/"
    local module_dir="$src_dir/$module_name/"
    local project_include_dir="$project_dir/include/"

    if [ ! -d "$project_dir" ]; then
        error "指定的项目目录不存在: $(make_path_pretty $project_dir) , 是否创建了该项目?"
    fi
    
    local possible_conflict_file=$(echo "$module_dir" | sed -n 's|\(.*[^/]\)/*$|\1|p')
    if [ -f "$possible_conflict_file" ]; then
        remove_conflict "$possible_conflict_file" "存在同名文件: $(make_path_pretty $possible_conflict_file) , 无法创建项目!!!"
    elif [ -d "$module_dir" ] && [ -n "$(ls -A $module_dir)" ]; then
        remove_conflict "$module_dir" "目标目录: $(make_path_pretty $module_dir) 存在且非空, 可能存在冲突文件!!!"
    fi

    if [ $? -ne 0 ]; then
        error "发生了冲突，且没有正确地删除冲突文件, 项目创建已取消!!!"
    fi

    mkdir -p "$module_dir/"
    create_new_module_template_file "$module_dir" "$module_name" "$project_include_dir"

    # 会破坏格式，故不使用(因为没有使用，所以这两句命令也没测试，慎用)
    # sed -i "1i\add_subdirectory($module_name)" "$src_dir/CMakeLists.txt"
    # sed -i "/target_link_libraries/{n ; a\\$module_name}" "$src_dir/CMakeLists.txt"

    return 0
}
# 创建项目
function create_project {
    local project_dir="$1/"
    local create_git_flag="$2"
    local src_dir="$project_dir/src/"
    local bin_dir="$project_dir/bin"
    local include_dir="$project_dir/include/"
    local build_dir="$project_dir/build/"
    local lib_dir="$project_dir/lib/"

    local main_file="$src_dir/main.c"
    local cmakelists_file="$project_dir/CMakeLists.txt"

    local project_name=$(get_project_name "$project_dir")
    local exe_name="$project_name"

    local possible_conflict_file=$(echo "$project_dir" | sed -n 's|\(.*[^/]\)/*$|\1|p')
    if [ -f "$possible_conflict_file" ]; then
        remove_conflict "$possible_conflict_file" "存在同名文件: $(make_path_pretty $possible_conflict_file) , 无法创建项目!!!"
    elif [ -d "$project_dir" ] && [ -n "$(ls -A $project_dir)" ]; then
        remove_conflict "$project_dir" "目标目录: $(make_path_pretty $project_dir) 存在且非空, 可能存在冲突文件!!!"
    fi

    if [ $? -ne 0 ]; then
        error "发生了冲突，且没有正确地删除冲突文件, 项目创建已取消!!!"
    fi

    echo "正在创建一个新的C项目, 位置为目录: $(make_path_pretty $project_dir)"
    create_new_project_template_file "$project_dir" "$project_name" "$exe_name" "$create_git_flag"
    mkdir -p "$src_dir" "$bin_dir" "$include_dir" "$build_dir" "$lib_dir"

    echo
    echo "成功创建以下目录或者文件:"
    echo "====================="
    echo 
    which tree > /dev/null
    if [ $? -eq 0 ]; then
        tree "$project_dir"
    else
        echo "$(make_path_pretty $project_dir)"
        my_tree "$project_dir"
    fi
    echo
    echo "====================="

    return 0
}

# 构建项目
function build_project {
    local project_dir="$1/"
    # local bin_dir="$project_dir/bin"
    # local include_dir="$project_dir/include/"
    local build_dir="$project_dir/build/"
    local cmakelists_file="$project_dir/CMakeLists.txt"

    if [ ! -d "$project_dir" ]; then
        error "指定的项目目录不存在: $(make_path_pretty $project_dir) , 是否创建了该项目?"
    elif [ ! -f "$cmakelists_file" ]; then
        error "指定的项目目录下不存在CMakeLists.txt文件: $(make_path_pretty $cmakelists_file) , 请先创建该文件"
    elif [ ! -d "$build_dir" ]; then
        echo "[WARNING]: 构建目录不存在, 正在创建目录: $(make_path_pretty $build_dir)"
        mkdir -p "$build_dir"
    fi

    echo "正在构建C项目, 构建位置为目录: $(make_path_pretty $build_dir)"
    cd "$build_dir"
    cmake ..
    if [ $? -ne 0 ]; then
        error "cmake执行失败, 请检查CMakeLists.txt文件是否正确"
    fi
    make
    if [ $? -ne 0 ]; then
        error "make执行失败, 请检查代码语法是否正确"
    fi
    cd - > /dev/null
    echo "成功构建项目, 可执行文件位于: $(make_path_pretty $project_dir/bin/)"
    echo
    return 0
}

# 运行可执行文件
function run_execute {
    local project_dir="$1/"
    local bin_dir="$project_dir/bin/"

    local project_name=$(get_project_name "$project_dir")
    local exe_name="$project_name"
    local exe_file="$bin_dir/$exe_name"

    if [ ! -d "$project_dir" ]; then
        error "指定的项目目录不存在: $(make_path_pretty $project_dir) , 是否创建了该项目?"
    elif [ ! -f "$exe_file" ]; then
        error "指定的项目目录下不存在可执行文件: $(make_path_pretty $exe_file) , 请先编译"
    fi 

    echo "正在运行C项目的可执行文件, 文件为: $(make_path_pretty $exe_file)"
    echo "-------------------- 输出结果 --------------------"
    # cd "$bin_dir"
    # ./"$exe_name"
    # cd - > /dev/null
    "$exe_file"
    echo "-------------------- 输出结束 --------------------"
    return 0
}

# 处理选项与命令行参数
set -- $(getopt bcghmnr "$@")
while [ -n "$1" ]; do
    # echo $1
    case "$1" in
        -b) IS_BUILD_PROJECT=true;;
        -c) IS_CREATE_PROJECT=true;;
        -g) IS_CREATE_ADDITIONAL_GIT=true;;
        -h) help; exit 0;;
        -m) IS_CREATE_MODULE=true;;
        -n) IS_NO_OUTPUT=true;;
        -r) IS_RUN_EXECUTE=true;;
        --) shift; break;;
        *)  error "未知的选项!!!";;
    esac
    shift
done

# 检测是否正确使用脚本
if [ -z "$1" ]; then
    help
    error "缺少必要的参数!!!"
elif [ ! $IS_CREATE_PROJECT = true ] && [ ! $IS_BUILD_PROJECT = true ] && [ ! $IS_RUN_EXECUTE = true ] && [ ! $IS_CREATE_MODULE = true ]; then
    help
    error "未指定任何操作!!!"
fi

if [ $IS_NO_OUTPUT = true ]; then
    exec 1>/dev/null
fi

# 创建一个模块
if [ $IS_CREATE_MODULE = true ]; then
    if [ ! $# -eq 2 ]; then
        help
        error "创建模块时必须且只能指定一个项目目录和一个模块名!!!"
    fi
    create_module "$1" "$2"
    exit $?
fi

# 创建项目、编译、执行
while [ -n "$1" ]; do
    agrument_target_dir="$1"
    result=0

    if [ $IS_CREATE_PROJECT = true ] && [ $result -eq 0 ]; then
        create_project "$agrument_target_dir" "$IS_CREATE_ADDITIONAL_GIT"
        result=$?
    fi
    
    if [ $IS_BUILD_PROJECT = true ] && [ $result -eq 0 ]; then
        build_project "$agrument_target_dir"
        result=$?
    fi
    
    if [ $IS_RUN_EXECUTE = true ] && [ $result -eq 0 ]; then
        run_execute "$agrument_target_dir"
        result=$?
    fi

    shift
done

exit 0