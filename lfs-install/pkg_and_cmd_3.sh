# 构建最终 LFS 系统需要安装的包与执行的命令
# 这个脚本在 chroot 环境下执行
# pkg_and_cmd_3.sh

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
#idx=0
idx="$(cat /tmp/lfs_now_idx)"

# 开始安装软件包

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
./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat; ok
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
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1; ok
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
sed -i 's|usr/bin/env |bin/|' run.sh.in; ok
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.2.6; ok
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
./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers; ok
make && make install; ok
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin; ok
mv -v /usr/bin/ifconfig /sbin; ok
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
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts; ok
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib                  \
                  -Dusethreads; ok
make && make install; ok
unset BUILD_ZLIB BUILD_BZIP2
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
perl Makefile.PL; ok
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
sed -i 's:\\\${:\\\$\\{:' intltool-update.in; ok
./configure --prefix=/usr; ok
make && make install; ok
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO; ok
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
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1; ok
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
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4; ok
make && make install; ok
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin; ok
mv -v /usr/lib/liblzma.so.* /lib; ok
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so; ok
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
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib; ok
make && make install; ok
for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /sbin/$target; ok
done
ln -sfv kmod /bin/lsmod; ok
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
sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in; ok
sed -e '/AppData/{N;N;p;s/\.appdata\./.metainfo./}' \
    -i gettext-tools/its/appdata.loc; ok
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.8.1; ok
make && make install; ok
chmod -v 0755 /usr/lib/preloadable_libintl.so; ok
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
make && make -C libelf install; ok
install -vm644 config/libelf.pc /usr/lib/pkgconfig; ok
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
sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
    -i include/Makefile.in; ok

sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I${includedir}/Cflags:/' \
    -i libffi.pc.in; ok
./configure --prefix=/usr --disable-static --with-gcc-arch=native; ok
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
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic; ok
make; ok
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile; ok
make MANSUFFIX=ssl install; ok
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
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes; ok
make && make install; ok
chmod -v 755 /usr/lib/libpython3.7m.so; ok
chmod -v 755 /usr/lib/libpython3.so; ok
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
patch -Np1 -i ../ninja-1.8.2-add_NINJAJOBS_var-1.patch; ok
python3 configure.py --bootstrap; ok
install -vm755 ninja /usr/bin/; ok
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja; ok
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja; ok
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
python3 setup.py build; ok
python3 setup.py install --root=dest; ok
cp -rv dest/* /; ok
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
ln -sf /tools/bin/true /usr/bin/xsltproc; ok
tar -xf ../systemd-man-pages-239.tar.xz; ok
sed '166,$ d' -i src/resolve/meson.build; ok
patch -Np1 -i ../systemd-239-glibc_statx_fix-1.patch; ok
sed -i 's/GROUP="render", //' rules/50-udev-default.rules.in; ok
mkdir -p build; ok
cd       build; ok

LANG=en_US.UTF-8                   \
meson --prefix=/usr                \
      --sysconfdir=/etc            \
      --localstatedir=/var         \
      -Dblkid=true                 \
      -Dbuildtype=release          \
      -Ddefault-dnssec=no          \
      -Dfirstboot=false            \
      -Dinstall-tests=false        \
      -Dkill-path=/bin/kill        \
      -Dkmod-path=/bin/kmod        \
      -Dldconfig=false             \
      -Dmount-path=/bin/mount      \
      -Drootprefix=                \
      -Drootlibdir=/lib            \
      -Dsplit-usr=true             \
      -Dsulogin-path=/sbin/sulogin \
      -Dsysusers=false             \
      -Dumount-path=/bin/umount    \
      -Db_lto=false                \
      ..; ok
LANG=en_US.UTF-8 ninja; ok
LANG=en_US.UTF-8 ninja install; ok
rm -rfv /usr/lib/rpm; ok
rm -f /usr/bin/xsltproc; ok
systemd-machine-id-setup; ok

cat > /lib/systemd/systemd-user-sessions << "EOF"
#!/bin/bash
rm -f /run/nologin
EOF
chmod 755 /lib/systemd/systemd-user-sessions; ok
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
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd; ok
make && make install; ok
mv -v /usr/lib/libprocps.so.* /lib; ok
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so; ok
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
mkdir -v build; ok
cd build; ok
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck; ok
make && make install; ok
make install-libs; ok
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a; ok
gunzip -v /usr/share/info/libext2fs.info.gz; ok
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info; ok
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
patch -Np1 -i ../coreutils-8.30-i18n-1.patch; ok
sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk; ok
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime; ok
FORCE_UNSAFE_CONFIGURE=1 make; ok
make install; ok
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin; ok
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin; ok
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin; ok
mv -v /usr/bin/chroot /usr/sbin; ok
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8; ok
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8; ok
mv -v /usr/bin/{head,sleep,nice} /bin; ok
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
sed -i '1 s/tools/usr/' /usr/bin/checkmk; ok
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
sed -i 's/extras//' Makefile.in; ok
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
sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in; ok
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c; ok
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c; ok
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h; ok
./configure --prefix=/usr --localstatedir=/var/lib/locate; ok
make && make install; ok
mv -v /usr/bin/find /bin; ok
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb; ok
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
PAGE=A4 ./configure --prefix=/usr; ok
make -j1; ok
make install; ok
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
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror; ok
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
./configure --prefix=/usr --sysconfdir=/etc; ok
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
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c; ok
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h; ok
./configure --prefix=/usr; ok
make && make install; ok
mv -v /usr/bin/gzip /bin; ok
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
sed -i /ARPD/d Makefile; ok
rm -fv man/man8/arpd.8; ok
sed -i 's/.m_ipt.o//' tc/Makefile; ok
make; ok
make DOCDIR=/usr/share/doc/iproute2-4.18.0 install; ok
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
patch -Np1 -i ../kbd-2.0.4-backspace-1.patch; ok
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure; ok
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in; ok
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock; ok
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
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c; ok
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
  ./configure --prefix=/usr                       \
              --sysconfdir=/etc                   \
              --localstatedir=/var                \
              --disable-static                    \
              --disable-doxygen-docs              \
              --disable-xml-docs                  \
              --docdir=/usr/share/doc/dbus-1.12.10 \
              --with-console-auth-dir=/run/console; ok
make && make install; ok
mv -v /usr/lib/libdbus-1.so.* /lib; ok
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so; ok
ln -sfv /etc/machine-id /var/lib/dbus; ok
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
mkdir -pv /var/lib/hwclock; ok
rm -vf /usr/include/{blkid,libmount,uuid}; ok
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.32.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python; ok
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
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.8.4 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap; ok
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
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin; ok
make && make install; ok
make -C doc install-html docdir=/usr/share/doc/tar-1.30; ok
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
sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm; ok
./configure --prefix=/usr --disable-static; ok
make && make install; ok
make TEXMF=/usr/share/texmf install-tex; ok
pushd /usr/share/info
rm -v dir
for f in *
  do install-info $f dir 2>/dev/null; ok
done
popd
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
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h; ok
./configure --prefix=/usr; ok
make && make install; ok
ln -sv vim /usr/bin/vi; ok
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1; ok
done
ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1; ok
echo "$pkg_fn" >> "$LFS"/tmp/lfs_build_ok
rmpack "$pkg_dir"
fi

# Set vim
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

# 再次清理
save_lib="ld-2.28.so libc-2.28.so libpthread-2.28.so libthread_db-1.0.so"

cd /lib

for LIB in $save_lib; do
    objcopy --only-keep-debug $LIB $LIB.dbg 
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB 
done    

save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.25
             libitm.so.1.0.0 libatomic.so.1.2.0" 

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB
done

unset LIB save_lib save_usrlib

echo_time_green "$script_name: 构建完成，接下来手动运行: /tools/bin/bash +h pkg_and_cmd_4.sh"

# end
t2="$(date +%s)"
t_mins=`echo "scale=2;($t2 -$t1)/60" | bc`
echo_time_green "$script_name: 编译安装总共用时 $t_mins 分钟"
echo "$script_name" >> "$LFS"/tmp/lfs_inst_result
exit 0
