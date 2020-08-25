#!/bin/bash
# main.sh

# 主脚本

script_path="$( cd "`dirname $0`"; pwd )"
script_name="$(basename $0)"
. "$script_path"/functions

LFS='/mnt/lfs'
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8

tmp_sys_script='4-build-tmp-system.sh'
final_sys_script='5-build-final-system.sh'
final_clean='6-final-clean.sh'

# Save to result file
if [ ! -d "$LFS"/tmp ]; then
    sudo mkdir -pv "$LFS"/tmp; is_cmd_ok
fi
sudo chmod a+wt "$LFS"/tmp; is_cmd_ok
sudo touch "$LFS"/tmp/lfs_inst_result; is_cmd_ok
sudo chmod 666 "$LFS"/tmp/lfs_inst_result; is_cmd_ok

# 1. 宿主机环境准备
echo_time_green "$script_name: 正在检查宿主机要求 ..."
bash 1-check-os.sh; is_cmd_ok
echo_time_green "$script_name: 正在检查宿主系统中命令版本要求 ..."
bash 2-version-check.sh; is_cmd_ok
echo_time_green "$script_name: 正在设置宿主系统环境 ..."
bash 3-set-env.sh; is_cmd_ok
echo_time_green "$script_name: 准备工作全部完成！"

# 2. 构建临时 LFS 系统
sudo \cp "$script_path"/"$tmp_sys_script" /home/lfs/; is_cmd_ok
sudo \cp "$script_path"/pkg_and_cmd_1.sh /home/lfs/; is_cmd_ok
#sudo \cp "$script_path"/pkg_and_cmd_2.sh /home/lfs/; is_cmd_ok
sudo \cp "$script_path"/functions /home/lfs/; is_cmd_ok
# 执行如下命令会报错
# bash: cannot set terminal process group (-1): Inappropriate ioctl for device
# bash: no job control in this shell
#sudo su - lfs -c "bash $tmp_sys_script"

# 切换用户后手动执行脚本
echo_time_green "$script_name: 即将切换到用户 lfs ..."
echo_time_green "$script_name: 切换后手动执行命令: bash $tmp_sys_script"
read -p "按下 回车 继续 "
sudo su - lfs

sudo chown -R root:root $LFS/tools; is_cmd_ok
sudo rm -rf /home/lfs/"$tmp_sys_script" 2>/dev/null; is_cmd_ok
sudo rm -rf /home/lfs/pkg_and_cmd_1.sh 2>/dev/null; is_cmd_ok
#sudo rm -rf /home/lfs/pkg_and_cmd_2.sh 2>/dev/null; is_cmd_ok
sudo rm -rf /home/lfs/functions 2>/dev/null; is_cmd_ok

# 3. 构建最终 LFS 系统
for dir in $LFS/{dev,proc,sys,run}; do
    if [ ! -d "$dir" ]; then
        sudo mkdir -v "$dir"; is_cmd_ok
    fi
done
if [ ! -c $LFS/dev/console ]; then
    sudo mknod -m 600 $LFS/dev/console c 5 1; is_cmd_ok
fi
if [ ! -c $LFS/dev/null ]; then
    sudo mknod -m 666 $LFS/dev/null c 1 3; is_cmd_ok
fi

# Mount
if ! mount | grep -q $LFS/dev; then
    sudo mount -v --bind /dev $LFS/dev; is_cmd_ok
fi
if ! mount | grep -q $LFS/dev/pts; then
    sudo mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620; is_cmd_ok
fi
if ! mount | grep -q $LFS/proc; then
    sudo mount -vt proc proc $LFS/proc; is_cmd_ok
fi
if ! mount | grep -q $LFS/sys; then
    sudo mount -vt sysfs sysfs $LFS/sys; is_cmd_ok
fi
if ! mount | grep -q $LFS/run; then
    sudo mount -vt tmpfs tmpfs $LFS/run; is_cmd_ok
fi

if [ -h $LFS/dev/shm ]; then
    sudo mkdir -pv $LFS/$(readlink $LFS/dev/shm); is_cmd_ok
fi

# 进入 chroot
sudo \cp "$script_path"/"$final_sys_script" "$LFS"; is_cmd_ok
sudo \cp "$script_path"/"$final_clean" "$LFS"; is_cmd_ok
sudo \cp "$script_path"/pkg_and_cmd_2.sh "$LFS"; is_cmd_ok
sudo \cp "$script_path"/pkg_and_cmd_3.sh "$LFS"; is_cmd_ok
sudo \cp "$script_path"/pkg_and_cmd_4.sh "$LFS"; is_cmd_ok
sudo \cp "$script_path"/pkg_list_2.txt "$LFS"; is_cmd_ok
sudo \cp "$script_path"/functions "$LFS"; is_cmd_ok

# 切换 chroot 后手动执行脚本
echo_time_green "$script_name: 即将切换到 chroot 环境 ..."
echo_time_green "$script_name: 切换后手动执行命令: bash $final_sys_script"
read -p "按下 回车 继续 "

sudo chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h

# 最后的清理工作
echo_time_green "$script_name: 正在执行最后的清理工作 ..."
echo_time_green "$script_name: 即将切换到最终版 LFS 的 chroot 环境 ..."
echo_time_green "$script_name: 切换后手动执行命令: bash $final_clean"
read -p "按下 回车 继续 "

sudo chroot "$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login

sudo rm -f "$LFS"/"$final_sys_script" 2>/dev/null; is_cmd_ok
sudo rm -f "$LFS"/"$final_clean" 2>/dev/null; is_cmd_ok
sudo rm -f "$LFS"/pkg_and_cmd_2.sh 2>/dev/null; is_cmd_ok
sudo rm -f "$LFS"/pkg_and_cmd_3.sh 2>/dev/null; is_cmd_ok
sudo rm -f "$LFS"/pkg_and_cmd_4.sh 2>/dev/null; is_cmd_ok
sudo rm -f "$LFS"/pkg_list_2.txt 2>/dev/null; is_cmd_ok
sudo rm -f "$LFS"/functions 2>/dev/null; is_cmd_ok
#sudo rm -f "$LFS"/tmp/lfs_inst_result
sudo rm -rf "$LFS"/tmp/*
echo_time_green "$script_name: LFS 系统构建完成！"
echo_time_green "$script_name: 现在你可以删除 /mnt/lfs/tools 目录了"

exit 0
