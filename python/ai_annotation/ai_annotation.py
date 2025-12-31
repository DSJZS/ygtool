import os
import sys
from openai import OpenAI

def ai_annotation(text: str):
    client = OpenAI(
        api_key=os.environ.get('DEEPSEEK_API_KEY'),
        base_url="https://api.deepseek.com"
    )

    what_is_your_want = '''
你是一个文档注释专家，你的用户是一个使用中文的新手程序员。
你要做的是接收用户给你的文档，然后对其进行详细的中文注释，帮助用户理解文档内容。
这里注释指的是不修改原有的文本(即原有文本不能被修改，需要保留，除非它不是中文，需要被翻译为中文，这种情况下需要翻译并替换原来的英文文本)，而是在适当的位置添加解释性的文字，说明代码的功能、逻辑和目的。
你可以在文章的末尾，或者某一个涉及专业用语的段落后面添加注释。
你的注释应该简明扼要，易于理解，避免使用过于复杂的术语。
你需要确保注释内容与原文内容紧密相关，帮助用户更好地理解文档。
你将输出给我一个Markdown格式的文档，包含原文和注释内容。
    '''

    example_text = '''下面是你要注释的文档: 
YES(1)                        User Commands                        YES(1)

NAME         

    yes - output a string repeatedly until killed

SYNOPSIS         

    yes [STRING]...
    yes OPTION

DESCRIPTION         

    Repeatedly output a line with all specified STRING(s), or 'y'.

    --help display this help and exit

    --version
            output version information and exit

AUTHOR         

    Written by David MacKenzie.

REPORTING BUGS         

    GNU coreutils online help:
    <https://www.gnu.org/software/coreutils/>
    Report any translation bugs to
    <https://translationproject.org/team/>

COPYRIGHT         

    Copyright © 2025 Free Software Foundation, Inc.  License GPLv3+:
    GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

SEE ALSO         

    Full documentation <https://www.gnu.org/software/coreutils/yes>
    or available locally via: info '(coreutils) yes invocation'

COLOPHON         

    This page is part of the coreutils (basic file, shell and text
    manipulation utilities) project.  Information about the project
    can be found at ⟨http://www.gnu.org/software/coreutils/⟩.  If you
    have a bug report for this manual page, see
    ⟨http://www.gnu.org/software/coreutils/⟩.  This page was obtained
    from the tarball coreutils-9.7.tar.xz fetched from
    ⟨http://ftp.gnu.org/gnu/coreutils/⟩ on 2025-08-11.  If you
    discover any rendering problems in this HTML version of the page,
    or you believe there is a better or more up-to-date source for the
    page, or you have corrections or improvements to the information
    in this COLOPHON (which is not part of the original manual page),
    send a mail to man-pages@man7.org
    '''
    example_response = '''# YES(1)                                                                     用户命令                                                                    YES(1)

## 名称
yes - 不断输出一个字符串，直到被杀死为止

## 概述
    yes [字符串]...
    >>ai: 这里的字符串即为不断输出的内容,如果字符串参数,默认为'y'
    yes 选项

## 描述
    不断输出包括所有指定字符串的一行，或者是 'y'。
    >>ai: "或者"即为不输入任何字符串参数

    --help 显示此帮助信息并退出

    --version
            显示版本信息并退出

## 作者
    由 David MacKenzie 编写。

## 报告错误
    GNU coreutils 的在线帮助： <https://www.gnu.org/software/coreutils/>
    请向 <https://translationproject.org/team/zh_CN.html> 报告翻译错误。

## 版权
    Copyright © 2022 Free Software Foundation, Inc.  License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
    This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

## 参见
    完整文档请见： <https://www.gnu.org/software/coreutils/yes>
    或者在本地使用： info '(coreutils) yes invocation'

## 跋
    此页面属于 coreutils（核心工具集，包含基础文件、Shell 和文本处理工具）项目。关于该项目的详细信息，请访问 ⟨http://www.gnu.org/software/coreutils/⟩。  
    如果您对此手册页有错误报告，请参见 ⟨http://www.gnu.org/software/coreutils/⟩。  
    此页面提取自 2025 年 8 月 11 日从 ⟨http://ftp.gnu.org/gnu/coreutils/⟩ 获取的 coreutils-9.7.tar.xz 压缩包。  
    若您在此 HTML 版本页面中发现任何渲染问题，或认为存在更好或更新的页面来源，或对此版权信息（并非原始手册页的组成部分）有更正或改进建议，请发送邮件至 man-pages@man7.org。

GNU coreutils 9.1                                                         2022年9月          '''

    response = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[
            {"role": "system", "content": what_is_your_want},
            {"role": "user", "content": example_text},
            {"role": "assistant", "content": example_response},
            {"role": "user", "content": text}
        ],
        stream=False
    )

    return response.choices[0].message.content
    
def main():
    argc = len(sys.argv)
    text = "下面是你要注释的文档: \n"
    result = ""

    if argc > 1:
        # 多个参数分别翻译
        for arg in sys.argv[1:]:
            text += f"{arg}\n"
        # result = ai_annotation(text)
        
    elif not sys.stdin.isatty():
        text = sys.stdin.read().strip()
        # result = ai_annotation(text)

    line_count = len(text.splitlines())

    if(line_count == 1):
        print("请输入内容")
    else:
        result = ai_annotation(text)
        print(result)

if __name__ == "__main__":
    main()