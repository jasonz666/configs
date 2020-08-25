#!/bin/bash
# count_num.sh

# 计算每行有几个数字，统计总共有多少数字
# 自定义变量名最好不要大写，可能会覆盖环境变量等等
sum=0
while read LINE; do
    tmp=$((`echo $LINE | sed 's/[^0-9]//g' | wc -m` - 1))
    echo $tmp
    let sum+=tmp
done < count_num.txt
echo "Total: $sum"
