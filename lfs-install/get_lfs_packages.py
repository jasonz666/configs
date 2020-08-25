#!/usr/bin/python3
# encoding:utf-8
# create at 2018-12-15

# 获取 LFS 系统构建过程中使用的
# 所有软件包与补丁包的下载地址和 MD5 校验和

import sys
import re
from urllib import request
from lxml import etree

##---------
# 变量定义
##---------

# 注意这个页面提供的总是最新版 LFS 使用的软件包
# 写此脚本时我使用的 LFS 版本是 v8.3-systemd
lfs_pkgs_html = 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter03/packages.html'
ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36'
url_fn = 'wget-list'
md5_fn = 'pkg-md5sums'

##-------------
# main
##-------------

# 版本判断
# 因为 python3 与 python2 的 urllib 库不太一样
# 所以必须指定 python3 运行此脚本
py_ver = sys.version_info.major + (sys.version_info.minor / 10)
if py_ver < 3.5:
    print('You must run me using python 3.x')
    exit(1)

# 请求页面
req = request.Request(lfs_pkgs_html, headers={'User-Agent': ua})
html = request.urlopen(req)

# 解析 html
parser = etree.HTMLParser()
root = etree.fromstring(html.read(), parser)
#print(etree.tostring(root, pretty_print=True, encoding='UTF-8').decode())
elem_list = root.findall('.//dd')

exp_pkg = re.compile(r'Download')
exp_md5 = re.compile(r'MD5 *sum')
pkg_url = []
md5_sum = []
pkg_name = []
for elem in elem_list:
    for child in elem:
        if exp_pkg.findall(child.text):
            #print('url: "%s"' % child[0].attrib['href'])
            pkg_url.append(child[0].attrib['href'])
            pkg_name.append(child[0].attrib['href'].split('/')[-1])
        if exp_md5.findall(child.text):
            md5_sum.append(child[0].text)

# 保存文件
#print(pkg_url, pkg_name, md5_sum)
with open(url_fn, 'w') as fd:
    pkg_url = [s + '\n' for s in pkg_url]
    fd.writelines(pkg_url)
with open(md5_fn, 'w') as fd:
    new_line = [
        md5_sum[i] + '  ' + pkg_name[i] + '\n' for i in range(len(md5_sum))]
    fd.writelines(new_line)
