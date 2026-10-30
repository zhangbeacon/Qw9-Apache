#!/bin/bash
# 用 gdb -X（单进程）观察 44790 PoC 在 memcpy 处的参数
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
EVID="$ROOT/evidence/CVE-2021-44790"
PREFIX=/opt/httpd
cat > /tmp/gdb44790.cmds <<'EOF'
set pagination off
set confirm off
break memcpy if $rdx > 0x100000000
commands
silent
printf "HUGE_MEMCPY size=%lu dst=%p src=%p\n", $rdx, $rdi, $rsi
bt 5
continue
end
run -X -f /opt/httpd/conf/httpd-44790-gdb.conf
EOF
sed 's/Listen 8082/Listen 8084/; s/ServerName 127.0.0.1:8082/ServerName 127.0.0.1:8084/' \
  "$ROOT/conf/httpd-44790.conf" > "$PREFIX/conf/httpd-44790-gdb.conf"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
sleep 0.5
cd "$PREFIX"
gdb -q -batch -x /tmp/gdb44790.cmds /opt/httpd/bin/httpd > "$EVID/gdb_memcpy.log" 2>&1 &
GPID=$!
for i in $(seq 1 40); do curl -s -o /dev/null http://127.0.0.1:8084/ && break; sleep 0.25; done
echo "gdb/server up; sending pad=3 request"
python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8084 /parsebody 3 > /tmp/gdb_resp.txt 2>/tmp/gdb_err.txt || true
sleep 3
kill "$GPID" 2>/dev/null || true
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
echo "=== gdb log ==="; cat "$EVID/gdb_memcpy.log"
echo "=== resp ==="; head -20 /tmp/gdb_resp.txt
