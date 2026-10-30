#!/bin/bash
# 子智能体 A：CVE-2023-25690 首次探索实验（临时，可重复运行）
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RT=/tmp/apacheA/25690
PREFIX=/opt/httpd
mkdir -p "$RT"
rm -f "$RT"/*
echo "== port check =="
python3 - <<'EOF'
import socket
for p in (8090, 8091):
    s = socket.socket()
    s.settimeout(0.2)
    try:
        s.connect(("127.0.0.1", p))
        print("PORT %d BUSY" % p)
    except Exception:
        print("PORT %d free" % p)
    s.close()
EOF
echo "== start backend =="
python3 "$ROOT/poc/CVE-2023-25690/backend.py" "$RT/backend.log" 8091 >"$RT/backend_console.log" 2>&1 &
BPID=$!
echo "backend pid=$BPID"
sleep 0.3
echo "== start httpd =="
setsid "$PREFIX/bin/httpd" -f "$ROOT/conf/CVE-2023-25690.conf" -DFOREGROUND >"$RT/console.log" 2>&1 &
HPID=$!
echo "httpd pid=$HPID"
sleep 0.8
ps -o pid,ppid,pgid,cmd -p "$HPID" 2>/dev/null
ps -ef | grep -E "$PREFIX/bin/httpd" | grep -v grep
echo "== send smuggle =="
python3 "$ROOT/poc/CVE-2023-25690/probe.py" 8090 smuggle "$RT/client_smuggle.txt"
sleep 0.5
echo "== send control =="
python3 "$ROOT/poc/CVE-2023-25690/probe.py" 8090 control "$RT/client_control.txt"
sleep 0.5
echo "== backend log =="
cat "$RT/backend.log"
echo "== httpd error_log (tail) =="
tail -40 "$RT/error_log" 2>/dev/null
echo "== httpd access_log =="
cat "$RT/access_log" 2>/dev/null
echo "== cleanup =="
kill -TERM -- -"$HPID" 2>/dev/null || kill -TERM "$HPID" 2>/dev/null
kill "$BPID" 2>/dev/null
sleep 0.5
ps -ef | grep -E "$PREFIX/bin/httpd|backend.py" | grep -v grep || true
