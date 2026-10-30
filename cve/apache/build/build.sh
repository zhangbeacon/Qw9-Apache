#!/bin/bash
# build.sh - Apache httpd 2.4.49 复现构建脚本（子智能体 C）
# 用法：bash build.sh [normal|asan]
#   normal -> /opt/httpd      （41773 / 22720 / 44224 复现）
#   asan   -> /opt/httpd-asan （CVE-2021-44790 溢出现场，ASAN 构建）
set -euo pipefail

MODE="${1:-normal}"
TARBALL="/mnt/e/强网拟态/cve/_downloads/httpd-2.4.49.tar.gz"
WORK="/root/work/apache"
SRC="$WORK/httpd-2.4.49"
OUT="/mnt/e/强网拟态/cve/apache/build"
mkdir -p "$OUT" "$WORK"

if [ "$MODE" = "asan" ]; then
  PREFIX="/opt/httpd-asan"
  SRC="$WORK/httpd-2.4.49-asan"
  LOG="$OUT/build-asan.log"
  EXTRA_CFLAGS="-g -O1 -fsanitize=address -fno-omit-frame-pointer"
  EXTRA_LDFLAGS="-fsanitize=address"
else
  PREFIX="/opt/httpd"
  LOG="$OUT/build-normal.log"
  EXTRA_CFLAGS="-g -O2"
  EXTRA_LDFLAGS=""
fi

exec > >(tee "$LOG") 2>&1
echo "===== build mode=$MODE prefix=$PREFIX $(date) ====="
echo "===== 源码核对 ====="
sha256sum "$TARBALL"

if [ ! -d "$SRC" ]; then
  mkdir -p "$SRC"
  # 直接从 tarball 解到目标目录（比 cp -a 整个构建树快很多）
  tar xzf "$TARBALL" -C "$SRC" --strip-components=1
fi

cd "$SRC"
grep -E 'AP_SERVER_(MAJOR|MINOR|PATCHLEVEL)_NUMBER' include/ap_release.h | head -3

if [ ! -f Makefile ] || [ "${RECONFIGURE:-0}" = "1" ]; then
  echo "===== configure ====="
  CFLAGS="$EXTRA_CFLAGS" LDFLAGS="$EXTRA_LDFLAGS" ./configure \
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

echo "===== make -j4 ====="
make -j4
echo "===== make install ====="
make install

echo "===== 产物核对 ====="
"$PREFIX/bin/httpd" -v
sha256sum "$PREFIX/bin/httpd"
file "$PREFIX/bin/httpd"
ldd "$PREFIX/bin/httpd" | head -20
echo "===== 模块列表 ====="
ls "$PREFIX/modules/" | grep -E 'cgi|lua|proxy|rewrite' || true
echo "===== build done $(date) ====="
