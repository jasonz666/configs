#!/bin/bash
# 5-build-final-system.sh

# 构建最终 LFS 系统
# 此脚本必须在 chroot 环境下运行

script_path="$( cd "`dirname $0`"; pwd )"
script_name="$(basename $0)"
. "$script_path"/functions

# Save to result
if [ -f "$LFS"/tmp/lfs_inst_result ]; then
    if grep -q "$script_name" "$LFS"/tmp/lfs_inst_result; then
        echo_time_prefix "$script_name: has executed OK. Skip"
        echo_time_green "$script_name: run 'exit' to logout"
        exit 0
    fi
fi

# 判断是否在 chroot 环境下
if [ -d /sources -a -d /tools ]; then
	:;
else
	echo_err_info "$script_name: 必须切换到 chroot 环境用于构建最终 LFS 系统"
	exit 1
fi

# 下面的命令都在 chroot 环境的 root 用户下执行

# 创建目录树
mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v  /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
 x86_64) mkdir -v /lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}

# 创建符合链接
ln -sv /tools/bin/{bash,cat,dd,echo,ln,pwd,rm,stty} /bin
ln -sv /tools/bin/{env,install,perl} /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.{a,so{,.6}} /usr/lib
for lib in blkid lzma mount uuid
do
    ln -sv /tools/lib/lib$lib.so* /usr/lib
done
ln -svf /tools/include/blkid    /usr/include
ln -svf /tools/include/libmount /usr/include
ln -svf /tools/include/uuid     /usr/include
install -vdm755 /usr/lib/pkgconfig
for pc in blkid mount uuid
do
    sed 's@tools@usr@g' /tools/lib/pkgconfig/${pc}.pc \
        > /usr/lib/pkgconfig/${pc}.pc
done
ln -sv bash /bin/sh
ln -sv /proc/self/mounts /etc/mtab

# 创建 passwd
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

# 创建 group
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
nogroup:x:99:
users:x:999:
EOF

# 重新打开 bash 以应用 passwd 与 group 文件中的用户和组信息
# exec 会替换当前的进程 进入交互式 shell 下面的命令就无法执行了
#exec /tools/bin/bash --login +h

# 创建关键日志文件
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

# 开始构建最终 LFS 系统
echo_time_green "$script_name: 开始构建最终 LFS 系统 ..."
#bash "$script_path"/pkg_and_cmd_2.sh; is_cmd_ok
/tools/bin/bash +h "$script_path"/pkg_and_cmd_2.sh; is_cmd_ok
#echo_time_green "$script_name: 最终 LFS 系统构建完成！"
#echo_time_green "$script_name: 请手动执行 'exit' 退出 chroot 环境"

echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
