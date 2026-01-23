# 添加所有模块子目录。每个模块会将自己编译成一个库（如 module1）
add_subdirectory(jobs)
add_subdirectory(csapp)

# 定义可执行程序
add_executable(yuansh main.c)

# 链接内部模块库
target_link_libraries(yuansh 
    PRIVATE
    jobs
    csapp
)

# 链接第三方库
target_link_libraries(yuansh 
    PRIVATE
    # ${CMAKE_SOURCE_DIR}/lib/
)

# 为目标单独设置头文件路径
target_include_directories(yuansh 
    PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)
