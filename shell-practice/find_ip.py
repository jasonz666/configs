#!/bin/env python
# find_ip.py

from __future__ import print_function

# 找出 find_ip_b.txt 文件中的 ip 是否在 ip 列表文件 find_ip_a.txt 中
# find_ip_b.txt 每行的格式形如 "72.14.231.75 IMEI=356262055742155"
# find_ip_a.txt 每行的内容为一个 ip 地址
file_a = 'find_ip_a.txt'
file_b = 'find_ip_b.txt'
a = [i.strip() for i in open(file_a)]
for i in open(file_b):
    if i.split()[0] in a:
        print(i, end='')
print()
