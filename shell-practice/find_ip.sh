#!/bin/bash
# find_ip.sh

# 找出 find_ip_b.txt 文件中的 ip 是否在 ip 列表文件 find_ip_a.txt 中
# find_ip_b.txt 每行的格式形如 "72.14.231.75 IMEI=356262055742155"
# find_ip_a.txt 每行的内容为一个 ip 地址

# FNR 表示 awk 到目前为止读取到的 当前文件 的行数
# NR 表示 awk 到目前为止读取到的 所有文件 的总行数
# a 更像是字典而不是数组，可以用字符串作为字典的键
awk 'NR==FNR {a[$1]=$0;next} NR>FNR{if($1 in a)print a[$1]}' find_ip_b.txt find_ip_a.txt
