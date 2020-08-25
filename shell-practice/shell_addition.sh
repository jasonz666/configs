#!/bin/bash
# shell_addition.sh

i=1
sum=0
while [[ $i -le 10 ]]; do
    # let 是 bash 的子命令
    # let 后表达式间不能有空格
    let sum+=i
    let i++
done
echo "sum = $sum"
