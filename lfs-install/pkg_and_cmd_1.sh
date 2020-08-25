# 构建临时 LFS 系统需要安装的包与执行的命令

# 打开别名扩展
shopt -s expand_aliases
script_path="$( cd "`dirname $0`"; pwd )"
script_name="$(basename $0)"
. "$script_path"/functions

LFS='/mnt/lfs'
LFS_SC="$LFS""/sources"
LFS_TLS="$LFS""/tools"
cd "$LFS_SC"; is_cmd_ok

alias unpack="cd $LFS_SC && tar xvf"
alias rmpack="cd $LFS_SC && rm -rf"

t1="$(date +%s)"

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

# Binutils
unpack binutils-2.31.1.tar.xz; is_cmd_ok
cd binutils-2.31.1; is_cmd_ok

mkdir build; is_cmd_ok
cd build; is_cmd_ok
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror; is_cmd_ok
make; is_cmd_ok
case $(uname -m) in
	x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64; is_cmd_ok ;;
esac
make install; is_cmd_ok
rmpack binutils-2.31.1; is_cmd_ok

# GCC
unpack gcc-8.2.0.tar.xz; is_cmd_ok
cd gcc-8.2.0; is_cmd_ok

tar -xf ../mpfr-4.0.1.tar.xz; is_cmd_ok
mv -v mpfr-4.0.1 mpfr; is_cmd_ok
tar -xf ../gmp-6.1.2.tar.xz; is_cmd_ok
mv -v gmp-6.1.2 gmp; is_cmd_ok
tar -xf ../mpc-1.1.0.tar.gz; is_cmd_ok
mv -v mpc-1.1.0 mpc; is_cmd_ok

for file in gcc/config/{linux,i386/linux{,64}}.h
do
	cp -uv $file{,.orig}; is_cmd_ok
	sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
		-e 's@/usr@/tools@g' $file.orig > $file; is_cmd_ok
	echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file; is_cmd_ok
	touch $file.orig; is_cmd_ok
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64; is_cmd_ok
 ;;
esac

mkdir build; is_cmd_ok
cd build; is_cmd_ok

../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++; is_cmd_ok

make && make install; is_cmd_ok
rmpack gcc-8.2.0; is_cmd_ok

# Linux API Headers
unpack linux-4.18.5.tar.xz; is_cmd_ok
cd linux-4.18.5; is_cmd_ok

make mrproper; is_cmd_ok
make INSTALL_HDR_PATH=dest headers_install; is_cmd_ok
cp -rv dest/include/* /tools/include; is_cmd_ok
rmpack linux-4.18.5; is_cmd_ok

# Glibc
unpack glibc-2.28.tar.xz; is_cmd_ok
cd glibc-2.28; is_cmd_ok

mkdir build; is_cmd_ok
cd build; is_cmd_ok
../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2             \
      --with-headers=/tools/include      \
      libc_cv_forced_unwind=yes          \
      libc_cv_c_cleanup=yes; is_cmd_ok
make && make install; is_cmd_ok
rmpack glibc-2.28; is_cmd_ok

# check ld
echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
tmp="$(readelf -l a.out | grep ': /tools')"
if ! echo "$tmp" | grep -q '/tools/lib64/ld-linux-x86-64.so.2'; then
	echo_err_info "$script_name: ld is not '/tools/lib64/ld-linux-x86-64.so.2'"
	exit 1
fi
rm -v dummy.c a.out; is_cmd_ok

# Libstdc++
cd "$LFS_SC"; is_cmd_ok
rmpack gcc-8.2.0; is_cmd_ok
unpack gcc-8.2.0.tar.xz; is_cmd_ok
cd gcc-8.2.0; is_cmd_ok

mkdir build; is_cmd_ok
cd build; is_cmd_ok
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/8.2.0; is_cmd_ok
make && make install; is_cmd_ok

# Binutils 2nd
cd "$LFS_SC"; is_cmd_ok
rmpack binutils-2.31.1; is_cmd_ok
unpack binutils-2.31.1.tar.xz; is_cmd_ok
cd binutils-2.31.1; is_cmd_ok

mkdir -v build; is_cmd_ok
cd build; is_cmd_ok

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot; is_cmd_ok

make && make install; is_cmd_ok

make -C ld clean; is_cmd_ok
make -C ld LIB_PATH=/usr/lib:/lib; is_cmd_ok
cp -v ld/ld-new /tools/bin; is_cmd_ok

# GCC 2nd
cd "$LFS_SC"; is_cmd_ok
rmpack gcc-8.2.0; is_cmd_ok
unpack gcc-8.2.0.tar.xz; is_cmd_ok
cd gcc-8.2.0; is_cmd_ok

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h; is_cmd_ok

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}; is_cmd_ok
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file; is_cmd_ok
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file; is_cmd_ok
  touch $file.orig; is_cmd_ok
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64; is_cmd_ok
  ;;
esac

tar -xf ../mpfr-4.0.1.tar.xz; is_cmd_ok
mv -v mpfr-4.0.1 mpfr; is_cmd_ok
tar -xf ../gmp-6.1.2.tar.xz; is_cmd_ok
mv -v gmp-6.1.2 gmp; is_cmd_ok
tar -xf ../mpc-1.1.0.tar.gz; is_cmd_ok
mv -v mpc-1.1.0 mpc; is_cmd_ok

mkdir -v build; is_cmd_ok
cd build; is_cmd_ok

CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp; is_cmd_ok

make && make install; is_cmd_ok
ln -sv gcc /tools/bin/cc; is_cmd_ok

# check ld again
echo 'int main(){}' > dummy.c
cc dummy.c
tmp="$(readelf -l a.out | grep ': /tools')"
if ! echo "$tmp" | grep -q '/tools/lib64/ld-linux-x86-64.so.2'; then
	echo_err_info "$script_name: ld is not '/tools/lib64/ld-linux-x86-64.so.2'"
	exit 1
fi
rm -v dummy.c a.out; is_cmd_ok

# Tcl
cd "$LFS_SC"; is_cmd_ok
rmpack gcc-8.2.0; is_cmd_ok
rmpack binutils-2.31.1; is_cmd_ok
unpack tcl8.6.8-src.tar.gz
cd tcl8.6.8; is_cmd_ok
cd unix; is_cmd_ok
./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
chmod -v u+w /tools/lib/libtcl8.6.so; is_cmd_ok
make install-private-headers; is_cmd_ok
ln -sv tclsh8.6 /tools/bin/tclsh; is_cmd_ok
rmpack tcl8.6.8; is_cmd_ok

# Expect
unpack expect5.45.4.tar.gz; is_cmd_ok
cd expect5.45.4; is_cmd_ok

cp -v configure{,.orig}; is_cmd_ok
sed 's:/usr/local/bin:/bin:' configure.orig > configure; is_cmd_ok

./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include; is_cmd_ok

make && make SCRIPTS="" install; is_cmd_ok
rmpack expect5.45.4; is_cmd_ok

# DejaGNU
unpack dejagnu-1.6.1.tar.gz; is_cmd_ok
cd dejagnu-1.6.1; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make install; is_cmd_ok
rmpack dejagnu-1.6.1; is_cmd_ok

# M4
unpack m4-1.4.18.tar.xz; is_cmd_ok
cd m4-1.4.18; is_cmd_ok

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c; is_cmd_ok
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack m4-1.4.18; is_cmd_ok

# Ncurses
unpack ncurses-6.1.tar.gz; is_cmd_ok
cd ncurses-6.1; is_cmd_ok

sed -i s/mawk// configure; is_cmd_ok
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite; is_cmd_ok
make && make install; is_cmd_ok
rmpack ncurses-6.1; is_cmd_ok

# Bash
unpack bash-4.4.18.tar.gz; is_cmd_ok
cd bash-4.4.18; is_cmd_ok

./configure --prefix=/tools --without-bash-malloc; is_cmd_ok
make && make install; is_cmd_ok
ln -sv bash /tools/bin/sh; is_cmd_ok
rmpack bash-4.4.18; is_cmd_ok

# Bison
unpack bison-3.0.5.tar.xz; is_cmd_ok
cd bison-3.0.5; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack bison-3.0.5; is_cmd_ok


# Bzip2
unpack bzip2-1.0.6.tar.gz; is_cmd_ok
cd bzip2-1.0.6; is_cmd_ok

make && make PREFIX=/tools install; is_cmd_ok
rmpack bzip2-1.0.6; is_cmd_ok

# Coreutils
unpack coreutils-8.30.tar.xz; is_cmd_ok
cd coreutils-8.30; is_cmd_ok

./configure --prefix=/tools --enable-install-program=hostname; is_cmd_ok
make && make install; is_cmd_ok
rmpack coreutils-8.30; is_cmd_ok

# Diffutils
unpack diffutils-3.6.tar.xz; is_cmd_ok
cd diffutils-3.6; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack diffutils-3.6; is_cmd_ok

# File
unpack file-5.34.tar.gz; is_cmd_ok
cd file-5.34; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack file-5.34; is_cmd_ok

# Findutils
unpack findutils-4.6.0.tar.gz; is_cmd_ok
cd findutils-4.6.0; is_cmd_ok

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c; is_cmd_ok
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c; is_cmd_ok
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack findutils-4.6.0; is_cmd_ok

# Gawk
unpack gawk-4.2.1.tar.xz; is_cmd_ok
cd gawk-4.2.1; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack gawk-4.2.1; is_cmd_ok

# Gettext
unpack gettext-0.19.8.1.tar.xz; is_cmd_ok
cd gettext-0.19.8.1; is_cmd_ok

cd gettext-tools; is_cmd_ok
EMACS="no" ./configure --prefix=/tools --disable-shared; is_cmd_ok

make -C gnulib-lib; is_cmd_ok
make -C intl pluralx.c; is_cmd_ok
make -C src msgfmt; is_cmd_ok
make -C src msgmerge; is_cmd_ok
make -C src xgettext; is_cmd_ok

cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin; is_cmd_ok
rmpack gettext-0.19.8.1; is_cmd_ok

# Grep
unpack grep-3.1.tar.xz; is_cmd_ok
cd grep-3.1; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack grep-3.1; is_cmd_ok

# Gzip
unpack gzip-1.9.tar.xz; is_cmd_ok
cd gzip-1.9; is_cmd_ok

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c; is_cmd_ok
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack gzip-1.9; is_cmd_ok

# Make
unpack make-4.2.1.tar.bz2; is_cmd_ok
cd make-4.2.1; is_cmd_ok

sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c; is_cmd_ok
./configure --prefix=/tools --without-guile; is_cmd_ok
make && make install; is_cmd_ok
rmpack make-4.2.1; is_cmd_ok

# Patch
unpack patch-2.7.6.tar.xz; is_cmd_ok
cd patch-2.7.6; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack patch-2.7.6; is_cmd_ok

# Perl
unpack perl-5.28.0.tar.xz; is_cmd_ok
cd perl-5.28.0; is_cmd_ok

sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth; is_cmd_ok
make; is_cmd_ok
cp -v perl cpan/podlators/scripts/pod2man /tools/bin; is_cmd_ok
mkdir -pv /tools/lib/perl5/5.28.0; is_cmd_ok
cp -Rv lib/* /tools/lib/perl5/5.28.0; is_cmd_ok
rmpack perl-5.28.0; is_cmd_ok

# Sed
unpack sed-4.5.tar.xz; is_cmd_ok
cd sed-4.5; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack sed-4.5; is_cmd_ok

# Tar
unpack tar-1.30.tar.xz; is_cmd_ok
cd tar-1.30; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack tar-1.30; is_cmd_ok

# Texinfo
unpack texinfo-6.5.tar.xz; is_cmd_ok
cd texinfo-6.5; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack texinfo-6.5; is_cmd_ok

# Util-linux
unpack util-linux-2.32.1.tar.xz; is_cmd_ok
cd util-linux-2.32.1; is_cmd_ok

./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            --without-ncurses              \
            PKG_CONFIG=""; is_cmd_ok

make && make install; is_cmd_ok
rmpack util-linux-2.32.1; is_cmd_ok

# Xz
unpack xz-5.2.4.tar.xz; is_cmd_ok
cd xz-5.2.4; is_cmd_ok

./configure --prefix=/tools; is_cmd_ok
make && make install; is_cmd_ok
rmpack xz-5.2.4; is_cmd_ok

# 清理无用内容
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*
rm -rf /tools/{,share}/{info,man,doc}
find /tools/{lib,libexec} -name \*.la -delete

# 改变属主
#sudo chown -R root:root $LFS/tools; is_cmd_ok
t2="$(date +%s)"
t_mins=`echo "scale=2;($t2 -$t1)/60" | bc`
echo_time_green "$script_name: 编译安装总共用时 $t_mins 分钟"
echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
