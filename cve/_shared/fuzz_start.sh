#!/bin/bash
set -u
F=/mnt/e/强网拟态/Apache项目/漏洞挖掘/fuzz
mkdir -p "$F"
pkill -9 -f fuzz_lua.py 2>/dev/null
pkill -9 -f httpd-asan 2>/dev/null
sleep 1
nohup python3 -u /mnt/e/强网拟态/cve/_shared/fuzz_lua.py > "$F/fuzz.stdout.log" 2>&1 &
echo $! > "$F/fuzz.pid"
sleep 6
echo "pid=$(cat "$F/fuzz.pid")"
pgrep -af fuzz_lua.py | head -2
tail -3 "$F/fuzz.stdout.log" 2>/dev/null
