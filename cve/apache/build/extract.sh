#!/bin/bash
# 解压并查看 httpd-2.4.49 源码（不编译）
set -e
mkdir -p /root/work/apache
cd /root/work/apache
if [ ! -d httpd-2.4.49 ]; then
  tar xzf /mnt/e/强网拟态/cve/_downloads/httpd-2.4.49.tar.gz
fi
cd httpd-2.4.49
echo "== version =="
grep -E 'AP_SERVER_BASEREVISION|AP_SERVER_MAJORVERSION|AP_SERVER_MINORVERSION|AP_SERVER_PATCHLEVEL' include/ap_release.h | head -6
echo "== cgi/lua/proxy files =="
ls modules/lua/ modules/generators/ modules/proxy/ | head -50
echo "== lua parsebody =="
sed -n '300,460p' modules/lua/lua_request.c
echo "== ap_discard_request_body =="
grep -n "ap_discard_request_body" server/protocol.c | head
