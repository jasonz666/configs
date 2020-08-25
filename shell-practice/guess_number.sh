#!/bin/bash
# guess_number.sh

# 获取 0~99 的随机数
num=$(($RANDOM % 100))

while :; do
    read -p "I will not tell you the number, guess it (0-99): " NUM
    if [[ $NUM -gt $num ]]; then
        echo "guess number is greater than it!"
    elif [[ $NUM -lt $num ]]; then
        echo "guess number is less than it!"
    else
        echo "yes, the number is '$num'"
        break
    fi
done
