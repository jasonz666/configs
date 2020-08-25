#!/bin/bash
# select_cmd.sh

## 输入数字，运行数字对应的命令
## 注意 bash 的 select 语句可以实现同样的功能
menu(){
    echo "** cmd menu **"
    echo -e "1--date\n2--ls\n3--who\n4--pwd"
}

menu
read -p "Choose a number to execute cmd: " NUM
case $NUM in
    1)
        date
        ;;
    2)
        ls
        ;;
    3)
        who
        ;;
    4)
        pwd
        ;;
    *)
        ;;
esac
