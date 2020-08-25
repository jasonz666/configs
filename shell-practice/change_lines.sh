#!/bin/bash
# change_lines.sh

# 方法1，使用三元运算符，含义同 C语言 的一样
echo "----> use awk's ternary operator <----"

# ORS 输出记录分隔符，默认为换行符
# NR 记录数，默认为文件的行数
# 三元表达式含义为，行编号是3的倍数 ORS="\n"，否则 ORS=" "
# {print} 默认打印当前记录，即打印当前行的内容
awk 'ORS=NR%3?" ":"\n"{print}' change_lines.txt

# 方法2，使用条件判断语句
echo -e "\n----> use awk's if/else <----"
awk '{if(NR%3) ORS=" "; else ORS="\n"; print}' change_lines.txt

# 方法3，使用 sed 的 N 命令，与方法1，2略不同
echo -e "\n----> use sed's command: N <----"

# N 是 sed 的命令，表示模式空间中当前行（行1）后面追加一行（行2）
# 变成多行模式空间，多行模式空间内容为 1\n2，继续追加一行（行3）为 1\n2\n3
# 分号分割多个命令，s 命令把换行符 \n 替换为空格，即从 "1\n2\n3" --> "1 2 3"
# 输出新行为 "1 2 3"，继续从下一行（行4）读取行到模式空间，重复以上过程
sed 'N;N;s/\n/_/g' change_lines.txt
