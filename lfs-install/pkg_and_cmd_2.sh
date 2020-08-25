# 构建最终 LFS 系统需要安装的包与执行的命令
# 这个脚本在 chroot 环境下执行
# pkg_and_cmd_2.sh

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
#alias ok=''

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

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
make mrproper; ok
make INSTALL_HDR_PATH=dest headers_install; ok
find dest/include \( -name .install -o -name ..install.cmd \) -delete; ok
cp -rv dest/include/* /usr/include; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
make install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then

# 恢复 ld 命令
if [ ! -f /tools/bin/ld-new ]; then
    mv -v /tools/bin/{ld,ld-new}; ok
    mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld-old,ld}; ok
    mv -v /tools/bin/{ld-old,ld}
fi

unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
patch -Np1 -i ../glibc-2.28-fhs-1.patch; ok
ln -sfv /tools/lib/gcc /usr/lib; ok
case $(uname -m) in
    i?86)    GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/8.2.0/include
            ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3; ok
    ;;
    x86_64) GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64; ok
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3; ok
    ;;
esac
rm -f /usr/include/limits.h; ok
mkdir -v build; ok
cd       build; ok

CC="gcc -isystem $GCC_INCDIR -isystem /usr/include" \
../configure --prefix=/usr                          \
             --disable-werror                       \
             --enable-kernel=3.2                    \
             --enable-stack-protector=strong        \
             libc_cv_slibdir=/lib; ok
unset GCC_INCDIR
make; ok
touch /etc/ld.so.conf; ok
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile; ok
make install; ok
cp -v ../nscd/nscd.conf /etc/nscd.conf; ok
mkdir -pv /var/cache/nscd; ok
install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf; ok
install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service; ok
mkdir -pv /usr/lib/locale; ok
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_CN -f UTF-8 zh_CN.UTF-8
localedef -i zh_CN -f GBK zh_CN.GBK

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2018e.tar.gz; ok

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}; ok

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}; ok
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}; ok
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}; ok
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO; ok
zic -d $ZONEINFO -p America/New_York; ok
unset ZONEINFO

ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; ok

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d; ok

# 调整工具链
mv -v /tools/bin/{ld,ld-old}; ok
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}; ok
mv -v /tools/bin/{ld-new,ld}; ok
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld; ok

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs; ok

# 测试调整后的工具链
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
tmp="$(readelf -l a.out | grep ': /lib')"
if ! echo "$tmp" | grep -q '/lib64/ld-linux-x86-64.so.2'; then
	echo_err_info "$script_name: toolchain adjust failed. ld is not '/lib64/ld-linux-x86-64.so.2'"
	exit 1
fi

tmp="$(grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log)"
if ! echo "$tmp" | grep -q '/usr/lib/.*crt1.o *succeeded'; then
	echo_err_info "$script_name: /usr/lib/../lib/crt1.o CHK FAILED"
	exit 1
fi
if ! echo "$tmp" | grep -q '/usr/lib/.*crti.o *succeeded'; then
	echo_err_info "$script_name: /usr/lib/../lib/crti.o CHK FAILED"
	exit 1
fi
if ! echo "$tmp" | grep -q '/usr/lib/.*crtn.o *succeeded'; then
	echo_err_info "$script_name: /usr/lib/../lib/crtn.o CHK FAILED"
	exit 1
fi

tmp="$(grep -B1 '^ /usr/include' dummy.log)"
if ! echo "$tmp" | grep -q '/usr/include'; then
	echo_err_info "$script_name: gcc include path is not '/usr/include'"
	exit 1
fi

tmp="$(grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g')"
if ! echo "$tmp" | grep -q 'SEARCH_DIR("/usr/lib")'; then
	echo_err_info "$script_name: gcc ld search path no '/usr/lib'"
	exit 1
fi
if ! echo "$tmp" | grep -q 'SEARCH_DIR("/lib")'; then
	echo_err_info "$script_name: gcc ld search path no '/lib'"
	exit 1
fi

tmp="$(grep "/lib.*/libc.so.6 " dummy.log)"
if ! echo "$tmp" | grep -q '/lib/libc.so.6 *succeeded'; then
	echo_err_info "$script_name: glibc '/lib/libc.so.6' not use"
	exit 1
fi

tmp="$(grep found dummy.log)"
if ! echo "$tmp" | grep -q '/lib/ld-linux-x86-64.so.2'; then
	echo_err_info "$script_name: dynamic loader is not '/lib/ld-linux-x86-64.so.2'"
	exit 1
fi
rm -v dummy.c a.out dummy.log
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr; ok
make && make install; ok
mv -v /usr/lib/libz.so.* /lib; ok
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr; ok
make && make install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
sed -i '/MV.*old/d' Makefile.in; ok
sed -i '/{OLDSUFF}/c:' support/shlib-install; ok
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-7.0; ok
make SHLIB_LIBS="-L/tools/lib -lncursesw"; ok
make SHLIB_LIBS="-L/tools/lib -lncurses" install; ok
mv -v /usr/lib/lib{readline,history}.so.* /lib; ok
chmod -v u+w /lib/lib{readline,history}.so.*; ok
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so; ok
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c; ok
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h; ok
./configure --prefix=/usr; ok
make && make install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
cat > bc/fix-libmath_h << "EOF"
#! /bin/bash
sed -e '1   s/^/{"/' \
    -e     's/$/",/' \
    -e '2,$ s/^/"/'  \
    -e   '$ d'       \
    -i libmath.h

sed -e '$ s/$/0}/' \
    -i libmath.h
EOF

ln -sv /tools/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6; ok
ln -sfv libncurses.so.6 /usr/lib/libncurses.so; ok
sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure; ok
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info; ok
make && make install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
if ! expect -c "spawn ls" | grep -q 'spawn ls'; then
	echo_err_info "$script_name: output is not 'spawn ls', compile Binutils can not continue."
	exit 1
fi

mkdir -v build; ok
cd       build; ok
../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib; ok
make tooldir=/usr; ok
make tooldir=/usr install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.1.2; ok
make &&  make html; ok
make check 2>&1 | tee gmp-check-log
tmp="$(awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log)"
if [ $tmp -ne 190 ]; then
	echo_err_info "$script_name: GMP test pass is not 190. GMP compile FAILED."
	exit 1
fi
make install && make install-html; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.1; ok
make && make html; ok
#make check
make install && make install-html; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0; ok
make && make html; ok
#make check
make install && make install-html; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
sed -i 's/groups$(EXEEXT) //' src/Makefile.in; ok
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \; ; ok
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \; ; ok
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \; ; ok
sed -i 's/1000/999/' etc/useradd; ok
./configure --sysconfdir=/etc --with-group-name-max-length=32; ok
make && make install; ok
mv -v /usr/bin/passwd /bin; ok
pwconv; ok
grpconv; ok
sed -i 's/yes/no/' /etc/default/useradd; ok
echo_time_green "$script_name: Set Password for Root."
passwd root
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64; ok
  ;;
esac
rm -f /usr/lib/gcc; ok
mkdir -v build; ok
cd       build; ok
SED=sed                               \
../configure --prefix=/usr            \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-libmpx         \
             --with-system-zlib; ok
make; ok
ulimit -s 32768; ok
make install; ok

ln -sv ../usr/bin/cpp /lib; ok
ln -sv gcc /usr/bin/cc; ok
install -v -dm755 /usr/lib/bfd-plugins; ok
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/8.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/; ok

# 再次测试 gcc
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
tmp="$(readelf -l a.out | grep ': /lib')"
if ! echo "$tmp" | grep -q '/lib64/ld-linux-x86-64.so.2'; then
	echo_err_info "$script_name: test 2nd: dynamic loader is not '/lib64/ld-linux-x86-64.so.2'"
	exit 1
fi

tmp="$(grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log)"
if ! echo "$tmp" | grep -q '/usr/lib/.*crt1.o *succeeded'; then
	echo_err_info "$script_name: /usr/lib/../lib/crt1.o CHK FAILED"
	exit 1
fi
if ! echo "$tmp" | grep -q '/usr/lib/.*crti.o *succeeded'; then
	echo_err_info "$script_name: /usr/lib/../lib/crti.o CHK FAILED"
	exit 1
fi
if ! echo "$tmp" | grep -q '/usr/lib/.*crtn.o *succeeded'; then
	echo_err_info "$script_name: /usr/lib/../lib/crtn.o CHK FAILED"
	exit 1
fi

tmp="$(grep -B4 '^ /usr/include' dummy.log)"
if ! echo "$tmp" | grep -q '/usr/include'; then
	echo_err_info "$script_name: gcc include path is not '/usr/include'"
	exit 1
fi
if ! echo "$tmp" | grep -q '/usr/local/include'; then
	echo_err_info "$script_name: gcc include path is not '/usr/local/include'"
	exit 1
fi
if ! echo "$tmp" | grep -q '/usr/lib/gcc/.*/include'; then
	echo_err_info "$script_name: gcc include path is not '/usr/lib/gcc/x86_64-xxx-linux-gnu/8.2.0/include'"
	exit 1
fi
if ! echo "$tmp" | grep -q '/usr/lib/gcc/.*/include-fixed'; then
	echo_err_info "$script_name: gcc include path is not '/usr/lib/gcc/x86_64-xxx-linux-gnu/8.2.0/include-fixed'"
	exit 1
fi

tmp="$(grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g')"
fline="$(wc -l "$script_path"/lib_search_dir.txt | cut -d' ' -f1)"
idx_tmp=0
for line in `cat "$script_path"/lib_search_dir.txt`; do
	echo "$tmp" | grep -q "$line" && ((idx_tmp++))
done
if [ $idx_tmp -ne $fline ]; then
	echo_err_info "$script_name: test 2nd: gcc ld search path chk FAILED"
	exit 1
fi

tmp="$(grep "/lib.*/libc.so.6 " dummy.log)"
if ! echo "$tmp" | grep -q '/lib/libc.so.6 *succeeded'; then
	echo_err_info "$script_name: glibc '/lib/libc.so.6' not use"
	exit 1
fi

tmp="$(grep found dummy.log)"
if ! echo "$tmp" | grep -q '/lib/ld-linux-x86-64.so.2'; then
	echo_err_info "$script_name: dynamic loader is not '/lib/ld-linux-x86-64.so.2'"
	exit 1
fi
rm -v dummy.c a.out dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib; ok
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch; ok
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile; ok
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile; ok
make -f Makefile-libbz2_so; ok
make clean; ok
make && make PREFIX=/usr install; ok
cp -v bzip2-shared /bin/bzip2; ok
cp -av libbz2.so* /lib; ok
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so; ok
rm -v /usr/bin/{bunzip2,bzcat,bzip2}; ok
ln -sv bzip2 /bin/bunzip2; ok
ln -sv bzip2 /bin/bzcat; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2; ok
make && make install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in; ok
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec; ok
make && make install; ok
mv -v /usr/lib/libncursesw.so.6* /lib; ok
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so; ok
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so; ok
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so; ok
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc; ok
done
rm -vf                     /usr/lib/libcursesw.so; ok
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so; ok
ln -sfv libncurses.so      /usr/lib/libcurses.so; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.4.48; ok
make && make install; ok
mv -v /usr/lib/libattr.so.* /lib; ok
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr         \
            --disable-static      \
            --libexecdir=/usr/lib \
            --docdir=/usr/share/doc/acl-2.2.53; ok
make && make install; ok
mv -v /usr/lib/libacl.so.* /lib; ok
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
sed -i '/install.*STALIBNAME/d' libcap/Makefile; ok
make && make RAISE_SETFCAP=no lib=lib prefix=/usr install; ok
chmod -v 755 /usr/lib/libcap.so; ok
mv -v /usr/lib/libcap.so.* /lib; ok
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
sed -i 's/usr/tools/'                 build-aux/help2man; ok
sed -i 's/testsuite.panic-tests.sh//' Makefile.in; ok
./configure --prefix=/usr --bindir=/bin; ok
make && make html; ok
make install; ok
install -d -m755           /usr/share/doc/sed-4.5; ok
install -m644 doc/sed.html /usr/share/doc/sed-4.5; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr; ok
make && make install; ok
mv -v /usr/bin/fuser   /bin; ok
mv -v /usr/bin/killall /bin; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
make && make install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.5; ok
make && make install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
sed -i "/math.h/a #include <malloc.h>" src/flexdef.h; ok
HELP2MAN=/tools/bin/true \
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4; ok
make && make install; ok
ln -sv flex /usr/bin/lex; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr --bindir=/bin; ok
make && make install; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Package
pkg_fn="${arr_pkg[$((++idx))]}"
if ! grep -q "$pkg_fn" "$LFS"/tmp/lfs_build_ok; then
unpack "$pkg_fn"; ok
pkg_dir="$(unpack "$pkg_fn" | head -1  | cut -d'/' -f1)"
cd "$pkg_dir"; ok
#cmds here
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/bash-4.4.18 \
            --without-bash-malloc               \
            --with-installed-readline; ok
make && make install; ok
mv -vf /usr/bin/bash /bin; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# 从这里开始需要切换新的 bash
# 下面的代码在另一个脚本中运行
#exec /bin/bash --login +h; ok
echo_time_green "$script_name: 部分构建完成，接下来手动运行: /bin/bash +h pkg_and_cmd_3.sh"
echo "$idx" > /tmp/lfs_now_idx

# end
t2="$(date +%s)"
t_mins=`echo "scale=2;($t2 -$t1)/60" | bc`
echo_time_green "$script_name: 编译安装总共用时 $t_mins 分钟"
echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
