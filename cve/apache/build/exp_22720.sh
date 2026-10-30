#!/bin/bash
# 子智能体 A：CVE-2022-22720 探索实验
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RT=/tmp/apacheA/22720
PREFIX=/opt/httpd
mkdir -p "$RT/htdocs/denied"
printf '<html><body>index</body></html>\n' > "$RT/htdocs/index.html"
printf 'SMUGGLED_SECOND_REQUEST\n' > "$RT/htdocs/smuggled.html"
rm -f "$RT"/error_log "$RT"/access_log "$RT"/console.log "$RT"/*.txt
echo "== port check =="
python3 - <<'EOF'
import socket
for p in (8090, 8091):
    s = socket.socket(); s.settimeout(0.2)
    try:
        s.connect(("127.0.0.1", p)); print("PORT %d BUSY" % p)
    except Exception:
        print("PORT %d free" % p)
    s.close()
EOF
echo "== start httpd =="
setsid "$PREFIX/bin/httpd" -f "$ROOT/conf/CVE-2022-22720.conf" -DFOREGROUND >"$RT/console.log" 2>&1 &
HPID=$!
echo "httpd pid=$HPID"
sleep 0.8
if ! python3 -c 'import socket,sys; s=socket.create_connection(("127.0.0.1",8090),1); s.sendall(b"GET /index.html HTTP/1.0\r\nHost: x\r\n\r\n"); print(s.recv(100)[:20]); s.close()' 2>/dev/null; then
  echo "SERVER START FAILED"; cat "$RT/console.log"; kill -TERM -- -"$HPID" 2>/dev/null; exit 2
fi
for sc in normal timeout403 chunkbad clbad; do
  echo "================ scenario: $sc ================"
  python3 "$ROOT/poc/CVE-2022-22720/probe.py" 8090 "$sc" "$RT/client_$sc.txt" || true
  sleep 0.5
done
echo "== access_log =="
cat "$RT/access_log" 2>/dev/null
echo "== error_log =="
cat "$RT/error_log" 2>/dev/null
echo "== cleanup =="
kill -TERM -- -"$HPID" 2>/dev/null || kill -TERM "$HPID" 2>/dev/null
sleep 0.6
ps -ef | grep "$PREFIX/bin/httpd" | grep -v grep || true
