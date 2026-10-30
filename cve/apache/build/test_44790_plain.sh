#!/bin/bash
# 在普通（非 ASAN）构建上先验证 44790 PoC 能触发 parsebody 崩溃
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
cd "$PREFIX"; : > logs/error_log; : > logs/access_log
"$PREFIX/bin/httpd" -f "$PREFIX/conf/httpd-44790-plain.conf" -DFOREGROUND > "$EVID/console_plain.log" 2>&1 &
HPID=$!
for i in $(seq 1 40); do curl -s -o /dev/null http://127.0.0.1:8083/ && break; sleep 0.25; done
echo "httpd pid=$HPID children_before=$(pgrep -P $HPID | tr '\n' ' ')"
echo "== check lua handler =="
curl -sS -i -X POST http://127.0.0.1:8083/parsebody -H 'Content-Type: text/plain' --data 'x' | head -10
echo "== send multipart overflow =="
python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8083 /parsebody > "$EVID/poc_response_plain.txt" 2> "$EVID/poc_stderr_plain.txt"
echo "poc rc=$?"
sleep 2
echo "children_after=$(pgrep -P $HPID | tr '\n' ' ')"
echo "== error log =="; tail -25 logs/error_log
echo "== console =="; tail -10 "$EVID/console_plain.log"
echo "== process =="; ps -ef | grep -F "$PREFIX/bin/httpd" | grep -v grep
kill "$HPID" 2>/dev/null || true
sleep 0.5
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
