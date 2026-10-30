#!/bin/bash
# 尝试用 LD_PRELOAD 强制 libasan 的 memcpy 拦截器生效，拿 44790 的 ASAN 报告
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
PREFIX=/opt/httpd-asan
EVID="$ROOT/evidence/CVE-2021-44790"
sed 's#/opt/httpd#/opt/httpd-asan#g; s/Listen 8082/Listen 8086/; s/ServerName 127.0.0.1:8082/ServerName 127.0.0.1:8086/' \
  "$ROOT/conf/httpd-44790.conf" > "$PREFIX/conf/httpd-44790-preload.conf"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
sleep 0.7
cd "$PREFIX"
export ASAN_OPTIONS="detect_leaks=0:abort_on_error=1:handle_segv=1:print_stacktrace=1"
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libasan.so.6 \
  "$PREFIX/bin/httpd" -X -f "$PREFIX/conf/httpd-44790-preload.conf" \
  > "$EVID/asan_preload_console.log" 2>&1 &
HPID=$!
for i in $(seq 1 60); do curl -s -o /dev/null http://127.0.0.1:8086/ && break; sleep 0.25; done
python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8086 /parsebody 3 > /dev/null 2>&1 || true
sleep 3
kill "$HPID" 2>/dev/null || true
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
echo "=== console size ==="; stat -c%s "$EVID/asan_preload_console.log"
echo "=== console ==="; head -60 "$EVID/asan_preload_console.log"
