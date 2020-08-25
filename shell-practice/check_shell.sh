#!/bin/bash
# check_shell.sh

# 检查一个脚本是否有语法错误
read -p "Please input a shell script filename: " FILE
if [ -f $FILE ]; then 
    sh -n $FILE
    if [ $? -ne 0 ]; then
        read -p "Input 'q' or 'Q' to quit, any other to edit $FILE: " RET
        if [[ "$RET" == "q" || "$RET" == "Q" ]]; then
            exit 0
        else
            vim $FILE
        fi
    else
        echo "check $FILE OK"
    fi
else
    echo "$FILE: file not found"
    exit 1
fi
