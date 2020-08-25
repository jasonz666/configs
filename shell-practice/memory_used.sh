#!/bin/bash
# memory_used.sh

# Sum total memory used via ps cmd
sum=0
for i in `ps aux | awk '/[0-9]/{print $6}'`; do
    let sum+=$i
done

# 方法1，for 循环
echo "----> USE FOR LOOP <----"
echo "$sum KB"

# 方法2，使用 awk 命令
echo -e "\n----> USE awk cmd-line <----"
ps aux | grep -v 'RSS TTY' | awk '{sum+=$6}END{print sum}'
