#!/bin/bash
# 额外构建 pristine httpd 2.4.50（用于 CVE-2021-42013 版本差分：
#   2.4.50 上单层 .%2e 应被 41773 修复拦截，而 .%%32%65 应仍可穿越）
set -euo pipefail
SRC=/root/work/miner/src/httpd-2.4.50
PREFIX=/opt/httpd-2450
LOG="/mnt/e/强网拟态/cve/apache/build/build-2450.log"
exec > >(tee "$LOG") 2>&1
echo "===== build httpd-2.4.50 prefix=$PREFIX $(date) ====="
grep -E 'AP_SERVER_(MAJOR|MINOR|PATCHLEVEL)_NUMBER' "$SRC/include/ap_release.h" | head -3
cd "$SRC"
if [ ! -f Makefile ]; then
  ./configure \
    --prefix="$PREFIX" \
    --with-apr=/usr \
    --with-apr-util=/usr \
    --with-pcre=/usr \
    --with-lua=/usr \
    --enable-mods-shared=most \
    --enable-cgi \
    --enable-cgid \
    --enable-lua \
    --enable-proxy \
    --enable-proxy-http \
    --enable-proxy-connect \
    --enable-so \
    --enable-rewrite \
    --enable-headers
fi
make -j4
make install
echo "===== 产物核对 ====="
"$PREFIX/bin/httpd" -v
sha256sum "$PREFIX/bin/httpd"
ls "$PREFIX/modules/" | grep -E 'alias|mime|dir|authz' | head
echo "===== 2.4.50 build done $(date) ====="
