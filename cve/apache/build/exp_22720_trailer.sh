#!/bin/bash
# 22720 追加实验：chunked malformed trailer 路径（read_chunked_trailers -> APR_EINVAL）
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RT=/tmp/apacheA/22720
PREFIX=/opt/httpd
mkdir -p "$RT/htdocs/denied"
printf '<html><body>index</body></html>\n' > "$RT/htdocs/index.html"
printf 'SMUGGLED_SECOND_REQUEST\n' > "$RT/htdocs/smuggled.html"
rm -f "$RT/error_log" "$RT/access_log" "$RT/console.log" "$RT"/trailer_*.txt
setsid "$PREFIX/bin/httpd" -f "$ROOT/conf/CVE-2022-22720.conf" -DFOREGROUND > "$RT/console.log" 2>&1 &
HPID=$!
sleep 0.8
curl -s -o /dev/null "http://127.0.0.1:8090/" || { echo START FAIL; exit 2; }
: > "$RT/access_log"
for sc in chunktrailer chunktrailer2 chunktrailer3 timeout403; do
  echo "================ $sc ================"
  python3 "$ROOT/poc/CVE-2022-22720/probe.py" 8090 "$sc" "$RT/trailer_$sc.txt" || true
  sleep 0.4
done
echo "== access_log =="; cat "$RT/access_log"
echo "== error_log =="; cat "$RT/error_log"
kill -TERM -- -"$HPID" 2>/dev/null || kill -TERM "$HPID" 2>/dev/null || true
sleep 0.5
kill -KILL -- -"$HPID" 2>/dev/null || true
