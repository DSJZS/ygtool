# 用处
用于快速创建一个空的C项目文件架构

# 具体用法
- 参考脚本的文本或者执行脚本的 `-h` 选项
- text_template/ 目录下的模板文件可用于规定额外生成文件
  脚本在用户使用 `-c` 选项时会默认根据格式创建对应的文件
  格式为: `<相对于项目根目录的路径>_<文件名>_template.txt`
  说起来有点奇怪，如果你不想模板文件被自动创建
  换句话说你对某个模板文件有特殊的用处，你可以用以下的格式命名
  格式为: `.<注释>_<文件名>_template.txt`
  此外, 这些模板文件中可以使用特定的宏
  格式为: `** macro **`
  目前仅支持以下的宏:
  - `** project_name_replace **` - 表示项目的名称 
  - `** exe_name_replace **`     - 表示可执行文件的名称(默认同项目的名称)
  值得注意的是下述的几个模板文件可以(适当地)修改，但是不建议删除
  - `text_template/.module_CMakeLists.txt_template.txt`
  - `text_template/root_.gitignore_template`
  - `text_template/root_CMakeLists.txt_template`
  - `text_template/src_CMakeLists.txt_template`
  - `text_template/src_main.c_template`

# 参考的C项目目录结构
``` 项目目录
project_name/                   # 项目根目录
├── src/                        # 源代码目录（核心逻辑）
│   ├── main.c                  # 程序入口（main函数）
│   ├── module1/                # 模块1（如网络模块）
│   │   ├── include/
│   │   │   └── module1_priv.h  # 模块1私有头文件（仅能被模块内使用）
│   │   ├── module1.c           # 模块1实现
│   │   └── CMakeLists.txt
│   ├── module2/                # 模块2（如工具函数）
│   │   ├── include/
│   │   │   └── module2_priv.h  # 模块2私有头文件（仅能被模块内使用）
│   │   ├── module2.c           # 模块2实现
│   │   └── CMakeLists.txt
│   └── CMakeLists.txt          # 组织src下的所有模块, 进行构建(可执行程序或者库)
├── include/                    # 公共头文件目录（供外部引用）
│   ├── module1.h               # 模块1的公共头文件 （对外接口）
|   └── module2.h           
├── lib/                        # 第三方库或静态/动态库
│   ├── libxxx.a                # 静态库
│   └── libxxx.so               # 动态库（Linux）/ libxxx.dll（Windows）
├── build/                      # 编译生成的各种文件
├── bin/                        # 最终可执行文件
├── CMakeLists.txt              # 定义项目、添加子目录、全局设置
└── README.md                   # 项目说明（功能、编译方式、使用方法）
```