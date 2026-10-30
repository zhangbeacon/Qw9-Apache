#!/bin/bash
# 尝试不同 ASAN_OPTIONS 以拿到 44790 的完整 ASAN 报告（-X 单进程）
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
PREFIX=/opt/httpd-asan
EVID="$ROOT/evidence/CVE-2021-44790"
sed 's#/opt/httpd#/opt/httpd-asan#g; s/Listen 8082/Listen 8085/; s/ServerName 127.0.0.1:8082/ServerName 127.0.0.1:8085/' \
  "$ROOT/conf/httpd-44790.conf" > "$PREFIX/conf/httpd-44790-x2.conf"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"

try_opt() {
  local tag="$1" opts="$2" pad="$3"
  pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
  sleep 0.7
  cd "$PREFIX"
  export ASAN_OPTIONS="$opts"
  "$PREFIX/bin/httpd" -X -f "$PREFIX/conf/httpd-44790-x2.conf" > "$EVID/asan_opt_${tag}.log" 2>&1 &
  local hpid=$!
  for i in $(seq 1 60); do curl -s -o /dev/null http://127.0.0.1:8085/ && break; sleep 0.25; done
  python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8085 /parsebody "$pad" > /dev/null 2>&1 || true
  sleep 2
  kill "$hpid" 2>/dev/null || true
  sleep 0.5
  pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
  echo "##### $tag (opts=$opts pad=$pad) size=$(stat -c%s "$EVID/asan_opt_${tag}.log")"
  grep -a -E 'AddressSanitizer|ERROR|SUMMARY|READ|WRITE|negative|allocation' "$EVID/asan_opt_${tag}.log" | head -10
}

try_opt A "detect_leaks=0:halt_on_error=1:abort_on_error=1:handle_segv=1" 3
try_opt B "detect_leaks=0:halt_on_error=1:abort_on_error=0:handle_segv=0" 3
try_opt C "detect_leaks=0:halt_on_error=1:abort_on_error=1:handle_segv=0" 3
