#!/bin/bash
# network_flow.sh

## 统计网络流量

## 单位转换
kb=1024
mb=1048576
gb=1073741824
interval_sec=1

## 处理命令行参数
## 这里的 -h 选项表示以人类可读方式显示结果
if [[ $# -gt 1 || ($# -eq 1 && $1 != "-h") ]]; then
    echo "usage: `basename $0` [-h]"
    exit 1
fi

## 用数组存储不同网络设备的数据
flow_sec(){
    arr_dev=($(cat /proc/net/dev | awk '/[0-9]/{print $1}'))
    arr_rec1=($(cat /proc/net/dev | awk '/[0-9]/{print $2}'))
    arr_tra1=($(cat /proc/net/dev | awk '/[0-9]/{print $10}'))
    sleep $1
    arr_rec2=($(cat /proc/net/dev | awk '/[0-9]/{print $2}'))
    arr_tra2=($(cat /proc/net/dev | awk '/[0-9]/{print $10}'))

    ## 必须在间隔时间后清屏
    clear
}

## 显示人类可读的单位
human_fmt(){
    if [[ $1 -lt $kb ]]; then
        tmp="$1"B
    elif [[ $1 -ge $kb && $1 -lt $mb ]]; then
        tmp=`expr $1 / $kb`KB
    elif [[ $1 -ge $mb && $1 -lt $gb ]]; then
        tmp=`expr $1 / $mb`MB
    else
        tmp=`expr $1 / $gb`GB
    fi
}

## 主循环
while :; do
    idx=0
    flow_sec $interval_sec
    echo "DEVICE RECEIVE TRANSMIT"
    for i in ${arr_dev[@]}; do
        rec=`expr ${arr_rec2[$idx]} - ${arr_rec1[$idx]}`
        tra=`expr ${arr_tra2[$idx]} - ${arr_tra1[$idx]}`
        if [[ $1 == "-h" ]]; then
            human_fmt $rec; rec=$tmp
            human_fmt $tra; tra=$tmp
            echo "$i $rec, $tra"
        else
            echo "$i $rec, $tra"
        fi
        let idx++ 
    done
done
