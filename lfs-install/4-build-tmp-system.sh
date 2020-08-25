#!/bin/bash
# 4-build-tmp-system.sh

# 构建临时 LFS 系统
# 此脚本必须在 lfs 用户下运行

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

if [ `whoami` != "lfs" ]; then
    echo_err_info "$script_name: 必须用 lfs 用户运行"
    exit 1
fi

# 开始构建临时 LFS 系统
echo_time_green "$script_name: 开始构建临时 LFS 系统 ..."
bash "$script_path"/pkg_and_cmd_1.sh; is_cmd_ok
echo_time_green "$script_name: 临时 LFS 系统构建完成！"
echo_time_green "$script_name: 请手动执行 'exit' 退出 lfs 用户"

echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
