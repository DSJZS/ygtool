# 使用说明
第一次使用时按照下述的步骤执行命令  
1. `sudo mkdir /archive`
2. `sudo groupadd Archivers`
3. `sudo chgrp Archivers /archive`
4. `sudo usermod -aG Archivers user_name`  其中`user_name` 要改为你自己的用户名
5. `sudo chmod 775 /archive`
6. `sudo chmod +t /archive`
7. `sudo mkdir /archive/Daily /archive/Hourly`
8. `sudo chgrp Archivers /archive/Daily /archive/Hourly`
9. `sudo chmod 775 /archive/Daily /archive/Hourly`
10. 用户重新登陆(一般来说重启电脑即可)

# 参考
**《Linux命令行与shell脚本编程大全(第四版)》**
