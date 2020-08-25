#!/bin/bash
# 6-final-clean.sh

# 最后的清理工作
# 此脚本必须在 chroot 环境下运行

script_path="$( cd "`dirname $0`"; pwd )"
script_name="$(basename $0)"
. "$script_path"/functions

tmp_building='4-build-tmp-system.sh'
final_building='5-build-final-system.sh'

# Save to result
if [ -f "$LFS"/tmp/lfs_inst_result ]; then
    if grep -q "$script_name" "$LFS"/tmp/lfs_inst_result; then
        echo_time_prefix "$script_name: has executed OK. Skip"
        echo_time_green "$script_name: run 'exit' to logout"
        exit 0
    fi
fi
if [ -f "$LFS"/tmp/lfs_inst_result ] && \
    grep -q "$tmp_building" "$LFS"/tmp/lfs_inst_result && \
    grep -q "$final_building" "$LFS"/tmp/lfs_inst_result; then
    :;
else
    echo_time_red "$script_name: run after '$tmp_building' and '$final_building' complete"
    exit 1
fi

# 判断是否在 chroot 环境下
if [ -d /sources -a -d /tools ]; then
    :;
else
    echo_err_info "$script_name: 必须切换到 chroot 环境用于构建最终 LFS 系统"
    exit 1
fi

# 下面的命令都在 chroot 环境的 root 用户下执行

# Clean
#rm -rf tools/
rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libz.a
find /usr/lib /usr/libexec -name \*.la -delete

# end
echo_time_green "$script_name: 最终 LFS 系统清理工作完成！"
echo_time_green "$script_name: 请手动执行 'exit' 退出 chroot 环境"

echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
