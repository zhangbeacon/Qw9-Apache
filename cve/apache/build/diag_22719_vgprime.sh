#!/bin/bash
# 诊断 CVE-2022-22719：Valgrind 下先发带 body 的 multipart（写 *rbuf），
# 同一连接再发无 body 的 multipart，观察是否变成悬垂堆指针读。
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RUN=/tmp/cve-2022-22719/vgprime
PREFIX=/opt/httpd
PORT=8095
CONF="$RUN/vg.conf"
rm -rf "$RUN"; mkdir -p "$RUN" "$PREFIX/lua" "$PREFIX/htdocs"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
[ -f "$PREFIX/htdocs/index.html" ] || echo '<html>lab</html>' > "$PREFIX/htdocs/index.html"
sed -e "s#/opt/httpd#${PREFIX}#g" -e "s#Listen 8095#Listen $PORT#" \
    -e "s#/tmp/cve-2022-22719#${RUN}#g" \
    "$ROOT/conf/CVE-2022-22719.conf" > "$CONF"
cd "$PREFIX"
valgrind --tool=memcheck --track-origins=yes --num-callers=25 \
         --log-file="$RUN/vg.%p.log" --error-limit=no \
         "$PREFIX/bin/httpd" -X -f "$CONF" > "$RUN/console.log" 2>&1 &
VPID=$!
for i in $(seq 1 120); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://127.0.0.1:$PORT/" 2>/dev/null || true)
  if [ -n "$code" ] && [ "$code" != "000" ]; then break; fi
  sleep 0.5
done
python3 "$ROOT/poc/CVE-2022-22719/crash_try.py" "$PORT" 262144 262144
sleep 3
kill $VPID 2>/dev/null; sleep 2; kill -9 $VPID 2>/dev/null
echo "=== valgrind ==="
for f in "$RUN"/vg.*.log; do
  echo "----- $f -----"
  grep -n -E 'uninitialised|Invalid|freed|ERROR SUMMARY' "$f" | head -40
done
