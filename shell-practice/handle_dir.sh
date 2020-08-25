#!/bin/bash
# handle_dir.sh

# 定时功能在 crontab 添加
now=`date +%H`
path="/data/log/"

# 在指定的时间清空文件
# 否则计算文件的大小然后保存到新文件
if [[ $now -eq 0  || $now -eq 12 ]]
then
    find $path -type f | xargs -i echo > {}
else
    find $path -type f | xargs -i du -sb {} > /tmp/`date +%Y%m%d%H%M%S`
fi
