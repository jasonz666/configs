#!/bin/bash
# version-check.sh

# Simple script to list version numbers of critical development tools
# Only support LFS 8.3-systemd requirement checking

export LC_ALL=C
script_path="$( cd "`dirname $0`"; pwd )"
script_name="$(basename $0)"
. "$script_path"/functions

# Save to result
if [ -f "$LFS"/tmp/lfs_inst_result ]; then
    if grep -q "$script_name" "$LFS"/tmp/lfs_inst_result; then
        echo_time_prefix "$script_name: has executed OK. Skip"
        exit 0
    fi
fi

# 终端必须是 bash
if [ `echo $SHELL` != '/bin/bash' ]; then
    echo_err_info "$script_name: 当前使用的终端必须是 bash"
    exit 1
fi

# 判断 bash 版本
ver_bash="$(bash --version | head -n1 | cut -d" " -f4 | cut -d'.' -f1-2)"
if [ `cmp_ver_num $ver_bash 3.2` -ne 1 ]; then
    echo_err_info "$script_name: bash 版本必须大于 3.2"
    exit 1
fi

# 设定 sh 指向 bash
sudo ln -sfv /bin/bash /bin/sh; is_cmd_ok

# 安装需要的包
! dpkg -l texinfo gawk bzip2 bison >/dev/null 2>&1 && \
sudo apt-get install -y texinfo gawk bzip2 bison

# 检查 binutils 版本
ver_ld="$(ld --version | head -n1 | cut -d" " -f3- | cut -d" " -f5)"
if [ `cmp_ver_num $ver_ld 2.25` -ne 1 ]; then
    echo_err_info "$script_name: binutils 版本必须大于 2.25"
    exit 1
fi

# 检查 bison
ver_bison="$(bison --version | head -n1 | cut -d" " -f4 | cut -d"." -f1-2)"
if [ `cmp_ver_num $ver_bison 2.7` -ne 1 ]; then
    echo_err_info "$script_name: bison 版本必须大于 2.7"
    exit 1
fi

# 设定 yacc 指向 bison
sudo ln -sfv /usr/bin/bison.yacc /usr/bin/yacc; is_cmd_ok

# 检查 bzip2 版本
ver_bz2="$(bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-)"
ver_bz2="$(echo $ver_bz2 | cut -d" " -f3 | cut -d',' -f1)"
if [ `cmp_ver_num $ver_bz2 1.0.4` -ne 1 ]; then
    echo_err_info "$script_name: bzip2 版本必须大于 1.0.4"
    exit 1
fi

# 检查 awk
ver_awk="$(/usr/bin/gawk --version | head -n1 | cut -d" " -f3 | cut -d"," -f1)"
if [ `cmp_ver_num $ver_awk 4.0.1` -ne 1 ]; then
    echo_err_info "$script_name: awk 版本必须大于 4.0.1"
    exit 1
fi

# 设定 awk 指向 gawk
sudo ln -sfv /usr/bin/gawk /usr/bin/awk; is_cmd_ok

# 检查其他命令的版本
ver_cu="$(chown --version | head -n1 | cut -d")" -f2 | cut -d" " -f2)"
if [ `cmp_ver_num $ver_cu 6.9` -ne 1 ]; then
    echo_err_info "$script_name: coreutils 版本必须大于 6.9"
    exit 1
fi

ver_df="$(diff --version | head -n1 | cut -d" " -f4)"
if [ `cmp_ver_num $ver_df 2.8.1` -ne 1 ]; then
    echo_err_info "$script_name: diffutils 版本必须大于 2.8.1"
    exit 1
fi

ver_fd="$(find --version | head -n1 | cut -d" " -f4 | cut -d"-" -f1)"
if [ `cmp_ver_num $ver_fd 4.2.31` -ne 1 ]; then
    echo_err_info "$script_name: findutils 版本必须大于 4.2.31"
    exit 1
fi

ver_gcc="$(gcc --version | head -n1 | awk '{print $NF}')"
ver_gpp="$(g++ --version | head -n1 | awk '{print $NF}')"
if [ `cmp_ver_num $ver_gcc 4.9` -ne 1 -o `cmp_ver_num $ver_gpp 4.9` -ne 1 ]; then
    echo_err_info "$script_name: gcc 版本必须大于 4.9"
    exit 1
fi

ver_glb="$(ldd --version | head -n1 | cut -d" " -f2- | awk '{print $NF}')"
if [ `cmp_ver_num $ver_glb 2.11` -ne 1 ]; then
    echo_err_info "$script_name: glibc 版本必须大于 2.11"
    exit 1
fi

ver_array[0]="$(grep --version | head -n1 | awk '{print $NF}')"
ver_array[1]="$(gzip --version | head -n1 | awk '{print $NF}')"
ver_array[2]="$(uname -r | awk -F'-' '{print $1}')"
ver_array[3]="$(m4 --version | head -n1 | awk '{print $NF}')"
ver_array[4]="$(make --version | head -n1 | awk '{print $NF}')"
ver_array[5]="$(patch --version | head -n1 | awk '{print $NF}')"
ver_array[6]="$(perl -V:version | cut -d"'" -f2)"
ver_array[7]="$(sed --version | head -n1 | awk '{print $NF}')"
ver_array[8]="$(tar --version | head -n1 | awk '{print $NF}')"
ver_array[9]="$(makeinfo --version | head -n1 | awk '{print $NF}')"
ver_array[10]="$(xz --version | head -n1 | awk '{print $NF}')"

name_array[0]="2.5.1a-grep"
name_array[1]="1.3.12-gzip"
name_array[2]="3.2-kernel"
name_array[3]="1.4.10-m4"
name_array[4]="4.0-make"
name_array[5]="2.5.4-patch"
name_array[6]="5.8.8-perl"
name_array[7]="4.1.5-sed"
name_array[8]="1.22-tar"
name_array[9]="4.7-texinfo"
name_array[10]="5.0.0-xz"

for i in `seq 0 10`; do
    if [ `cmp_ver_num ${ver_array[$i]} ${name_array[$i]}` -ne 1 ]; then
        name_tmp="$(echo ${name_array[$i]} | cut -d"-" -f2)"
        echo_err_info "$script_name: $name_tmp 版本必须大于 ${ver_array[$i]}"
        exit 1
    fi
done

echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]; then
    echo "g++ compilation OK";
    rm -f dummy.c dummy
else
    echo "g++ compilation failed";
    rm -f dummy.c dummy
    exit 1
fi
echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
