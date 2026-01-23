aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR} SRC_LIST)

add_library(csapp STATIC ${SRC_LIST})

# 额外设置源文件
target_sources(csapp
    PRIVATE
)

# 额外设置头文件路径
target_include_directories(csapp
    PUBLIC
    ${CMAKE_SOURCE_DIR}/include
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# 额外链接第三方库
target_link_libraries(csapp 
    PRIVATE
)