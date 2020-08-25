#!/bin/bash
# check-os.sh

# 构建 LFS 系统的过程在指定的电脑上运行
# 所以检查操作系统和 CPU 类型
# 因为 LFS 的构建过程中某些包会对宿主机 CPU 优化
# 这些优化的包放到别的宿主机运行可能出问题

# 脚本文件所在的绝对路径
script_path="$( cd "`dirname $0`"; pwd )"
. "$script_path"/functions

# 脚本文件名称
script_name="$(basename $0)"

host_os='Ubuntu 18.04'
cpu_spec='Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz'
cpu_name="$(cat /proc/cpuinfo | grep 'model name' | head -1 | awk -F':' '{print $2}')"
cpu_name="$(echo $cpu_name | sed -r 's/(^ +)[^ ]|[^ ]( +$)/x/')"

# Save to result
if [ -f "$LFS"/tmp/lfs_inst_result ]; then
    if grep -q "$script_name" "$LFS"/tmp/lfs_inst_result; then
        echo_time_prefix "$script_name: has executed OK. Skip"
        exit 0
    fi
fi

# 判断 CPU
if [ "$cpu_spec" != "$cpu_name" ]; then
    echo_err_info "$script_name: 宿主机 CPU 必须是 '$cpu_spec'"
    exit 1
else
    echo_time_prefix "$script_name: CPU is '$cpu_name'"
fi

# 判断系统类型
if [ -f /etc/issue ] && grep -iq "$host_os" /etc/issue; then
    echo_time_prefix "$script_name: Host OS is '$host_os'"
else
    echo_err_info "$script_name: 宿主机系统必须是 '$host_os'"
    exit 1
fi

# 判断系统位数
if [ "$(uname -m)" != "x86_64" ]; then
    echo_err_info "$script_name: 系统必须是 64 位"
    exit 1
else
    echo_time_prefix "$script_name: Host OS is x86_64"
fi
echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
