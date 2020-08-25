#!/bin/bash
# 3-set-env.sh

# 设置宿主机系统环境为 LFS 构建做准备

# 打开别名扩展
shopt -s expand_aliases
script_path="$( cd "`dirname $0`"; pwd )"
script_name="$(basename $0)"
. ${script_path}/functions

# 安装需要的包
! dpkg -l curl python3 python3-pip tsocks >/dev/null 2>&1 && \
sudo apt-get install curl python3 python3-pip tsocks >/dev/null

# 设置代理函数
set_proxy() {
    echo_time_red "下载 LFS 的软件包和补丁可能非常慢，建议使用（全局）代理下载"
    read -p "仍然继续下载输入 yes，使用代理输入 no (yes/no): " ret

    if [ "$ret" != "yes" ]; then
        read -p "输入代理服务器的 ip:port (比如 192.168.1.130:1080): " p_server
    fi

    if [ "$p_server" != "" ]; then
        #echo_time_green "$script_name: 正在使用代理下载 ..."
        echo_time_red "正在安装 tsocks 工具 ..."
        read -p "输入代理服务器所在局域网的掩码 (如 24 位掩码就输入 255.255.255.0): " p_mask
        if [ "$p_mask" == "" ]; then p_mask="255.255.255.0"; fi
        p_ip="$(echo $p_server | cut -d':' -f1)"; is_cmd_ok
        p_port="$(echo $p_server | cut -d':' -f2)"; is_cmd_ok
        p_gw="$(echo $p_server | cut -d':' -f1 | sed 's/\.[^.]\+$//')"; is_cmd_ok
        p_gw="$(echo "$p_gw"".0/$p_mask")"
        sudo sed -i "s#^server *= *.*\$#server = $p_ip#" /etc/tsocks.conf; is_cmd_ok
        sudo sed -i "s#^server_port *= *.*\$#server_port = $p_port#" /etc/tsocks.conf; is_cmd_ok
        sudo sed -i "s#server_type *= *.*\$#server_type = 5#" /etc/tsocks.conf; is_cmd_ok
        sudo sed -i "s#local *= *.*\$#local = $p_gw#" /etc/tsocks.conf; is_cmd_ok
    fi
    proxy_ret="$ret"
}

# Save to result
if [ -f "$LFS"/tmp/lfs_inst_result ]; then
    if grep -q "$script_name" "$LFS"/tmp/lfs_inst_result; then
        echo_time_prefix "$script_name: has executed OK. Skip"
        exit 0
    fi
fi

# 创建目录 /mnt/lfs
if [ ! -d /mnt/lfs ]; then
    echo_time_prefix "$script_name: 创建 /mnt/lfs 目录"
    sudo mkdir -v /mnt/lfs/; is_cmd_ok
else
    echo_time_prefix "$script_name: 目录 /mnt/lfs 已存在"
fi

# 设置环境变量
sudo bash -c "echo 'export LFS=/mnt/lfs' > /etc/profile.d/lfs.sh"; is_cmd_ok
. /etc/profile.d/lfs.sh; is_cmd_ok

# 检查 LFS 分区是否准备好
is_cmd_exist df
lfs_space="$(df -h | grep '/mnt/lfs$' | awk '{print $(NF-2)}')"
if [ "$lfs_space" == "" ]; then
    echo_err_info "$script_name: 请建立一个新分区 然后挂载到 /mnt/lfs 下"
    echo_err_info "$script_name: 新分区专门用于构建 LFS 系统 最小需要 12G"
    echo_err_info "$script_name: 然后把 /mnt/lfs 新分区挂载加入 /etc/fstab"
    exit 1
fi

lfs_space="$(echo $lfs_space | sed 's/G//')"
#if [ "$lfs_space" -lt 12 ]; then
if [ `echo "$lfs_space < 12" | bc` -eq 1 ]; then
    echo_err_info "$script_name: 构建 LFS 最少需要 12G 空间"
    exit 1
fi

# 创建源码和工具链目录
cd /mnt/lfs; is_cmd_ok
if [ ! -d /mnt/lfs/sources ]; then
    sudo mkdir -v sources; is_cmd_ok
fi
if [ ! -d /mnt/lfs/tools ]; then
    sudo mkdir -v tools; is_cmd_ok
fi

sudo chmod a+wt sources/; is_cmd_ok
cd sources/; is_cmd_ok

# 安装 lxml 库
if ! pip3 show lxml >/dev/null; then
    sudo -H pip3 install lxml; is_cmd_ok
fi

#rm -rf /mnt/lfs/sources/* 2>/dev/null
python3 "$script_path"/get_lfs_packages.py; is_cmd_ok
python3 "$script_path"/get_lfs_patches.py; is_cmd_ok

# 测试代理是否就绪 时长10s
if ! tsocks curl -m 10 -I https://google.com 2>/dev/null | grep -Eiq '^http.*301|^http.*200'; then
    set_proxy
else
    proxy_ret="no"
fi
if [ "$proxy_ret" != "yes" ]; then
    ## 在非交互式 shell 下 alias 别名扩展默认是关闭的
    ## 用 bash 命令运行的脚本就是非交互式 shell
    ## 必须先打开别名扩展下面的命令才有效
    alias wget='tsocks wget'
fi

if [ -f pkg-md5sums -a -f patches-md5sums ]; then
    md5sum -c pkg-md5sums 2>/dev/null | grep FAILED > pkg-md5sums-failed.txt
    md5sum -c patches-md5sums 2>/dev/null | grep FAILED > patches-md5sums-failed.txt
    if [ "$(head -1 pkg-md5sums-failed.txt)" != "" ]; then
        echo_time_green "$script_name: 正在下载剩余的包 ..."
        for line in `awk -F':' '{print $1}' pkg-md5sums-failed.txt`; do
            \rm -f ./"$line".*
            url="$(grep "$line" wget-list)"
            wget -c "$url"
        done
    fi
    if [ "$(head -1 patches-md5sums-failed.txt)" != "" ]; then
        echo_time_green "$script_name: 正在下载剩余的补丁 ..."
        for line in `awk -F':' '{print $1}' patches-md5sums-failed.txt`; do
            \rm -f ./"$line".*
            url="$(grep "$line" wget-list-patches)"
            wget -c "$url"
        done
    fi
fi

md5sum -c pkg-md5sums; is_cmd_ok
md5sum -c patches-md5sums; is_cmd_ok
echo_time_prefix "$script_name: 所有下载的文件 校验 OK"

# 创建软链接
sudo ln -svf /mnt/lfs/tools /; is_cmd_ok

# 这两个命令不要检查返回值
sudo groupadd lfs 2>/dev/null
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs 2>/dev/null

# 更改工具链和源码目录的属主
sudo chown -v lfs /mnt/lfs/tools; is_cmd_ok
sudo chown -v lfs /mnt/lfs/sources; is_cmd_ok

# 复制构建临时 LFS 系统的 bash 初始化文件
sudo \cp "$script_path"/.bash_profile_1 /home/lfs/.bash_profile; is_cmd_ok
sudo \cp "$script_path"/.bashrc_1 /home/lfs/.bashrc; is_cmd_ok
sudo chown lfs.lfs /home/lfs/.bash_profile; is_cmd_ok
sudo chown lfs.lfs /home/lfs/.bashrc; is_cmd_ok
sudo chmod 644 /home/lfs/{.bashrc,.bash_profile}; is_cmd_ok
echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
