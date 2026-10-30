#!/bin/bash
# ASAN + -X 单进程，直接捕获 stderr 里的 ASAN 报告
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
PREFIX=/opt/httpd-asan
EVID="$ROOT/evidence/CVE-2021-44790"
sed 's#/opt/httpd#/opt/httpd-asan#g; s/Listen 8082/Listen 8084/; s/ServerName 127.0.0.1:8082/ServerName 127.0.0.1:8084/' \
  "$ROOT/conf/httpd-44790.conf" > "$PREFIX/conf/httpd-44790-x.conf"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
sleep 0.7
cd "$PREFIX"
export ASAN_OPTIONS="detect_leaks=0:abort_on_error=1:handle_segv=1:fast_unwind_on_fatal=1"
"$PREFIX/bin/httpd" -X -f "$PREFIX/conf/httpd-44790-x.conf" > "$EVID/asan_x_console.log" 2>&1 &
HPID=$!
for i in $(seq 1 60); do curl -s -o /dev/null http://127.0.0.1:8084/ && break; sleep 0.25; done
echo "single-process httpd pid=$HPID"
python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8084 /parsebody 3 > "$EVID/asan_x_poc_response.txt" 2> "$EVID/asan_x_poc_stderr.txt" || true
sleep 3
kill "$HPID" 2>/dev/null || true
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
echo "=== console size ==="; ls -l "$EVID/asan_x_console.log"
echo "=== console (ASAN) ==="; head -80 "$EVID/asan_x_console.log"
