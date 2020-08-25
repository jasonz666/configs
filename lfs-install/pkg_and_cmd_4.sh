# 构建最终 LFS 系统需要安装的包与执行的命令
# 这个脚本在 chroot 环境下执行
# pkg_and_cmd_4.sh

# 打开别名扩展
shopt -s expand_aliases
script_path="$( cd "`dirname $0`"; pwd )"
script_name="$(basename $0)"
. "$script_path"/functions

LFS=''
LFS_SC="$LFS""/sources"
LFS_TLS="$LFS""/tools"

alias unpack="cd $LFS_SC && tar xvf"
alias rmpack="cd $LFS_SC && rm -rf"
alias ok='is_cmd_ok'

t1="$(date +%s)"
cd "$LFS_SC"; ok

# Save to result
if [ -f "$LFS"/tmp/lfs_inst_result ]; then
    if grep -q "$script_name" "$LFS"/tmp/lfs_inst_result; then
        echo_time_prefix "$script_name: has executed OK. Skip"
        exit 0
    fi
fi

# 删除源码目录
for dn in `find . -maxdepth 1 -type d`; do
    if echo "$dn" | grep -q '^\..\+'; then
        rm -rf "$dn" 2>/dev/null
    fi
done

# 读取包名到数组
s_pkg_fn="pkg_list_2.txt"
if [ -f "$script_path"/"$s_pkg_fn" ]; then
	idx=0
	while read line; do
		arr_pkg[$((++idx))]="$line"
	done < "$script_path"/"$s_pkg_fn"
else
	echo_err_info "$script_name: 找不到源码包列表文件 $s_pkg_fn"
	exit 1
fi
idx=0

# 开始安装软件包
# 清理步骤

#exec /tools/bin/bash
/tools/bin/find /usr/lib -type f -name \*.a \
   -exec /tools/bin/strip --strip-debug {} ';'

/tools/bin/find /lib /usr/lib -type f \( -name \*.so* -a ! -name \*dbg \) \
   -exec /tools/bin/strip --strip-unneeded {} ';'

/tools/bin/find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
    -exec /tools/bin/strip --strip-all {} ';'

#rm -rf /tmp/*

t2="$(date +%s)"
t_mins=`echo "scale=2;($t2 -$t1)/60" | bc`
echo_time_green "$script_name: 编译安装总共用时 $t_mins 分钟"
echo_time_green "$script_name: 最终 LFS 系统构建完成！"
echo_time_green "$script_name: 请手动执行 'exit' 退出 chroot 环境"
echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
