#!/bin/bash
# 诊断 CVE-2022-22719：multipart Content-Type + 无 body，观察 plain/ASAN 行为
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RUN=/tmp/cve-2022-22719
mkdir -p "$RUN" /opt/httpd/lua /opt/httpd/htdocs /opt/httpd-asan/lua /opt/httpd-asan/htdocs
cp -f "$ROOT/conf/lua/parsebody.lua" /opt/httpd/lua/parsebody.lua
cp -f "$ROOT/conf/lua/parsebody.lua" /opt/httpd-asan/lua/parsebody.lua
[ -f /opt/httpd/htdocs/index.html ] || echo '<html>lab</html>' > /opt/httpd/htdocs/index.html
[ -f /opt/httpd-asan/htdocs/index.html ] || echo '<html>lab</html>' > /opt/httpd-asan/htdocs/index.html

run_case() {
  local PREFIX="$1" TAG="$2" PORT="$3"
  echo "######## $TAG ($PREFIX) ########"
  rm -f "$RUN"/httpd.pid "$RUN"/error_log "$RUN"/access_log
  sed -e "s#/opt/httpd#${PREFIX}#g" -e "s#Listen 8095#Listen $PORT#" \
      -e "s#/tmp/cve-2022-22719#${RUN}/${TAG}#g" \
      "$ROOT/conf/CVE-2022-22719.conf" > "$RUN/${TAG}.conf"
  mkdir -p "$RUN/${TAG}"
  if [ "$PREFIX" = "/opt/httpd-asan" ]; then
    export ASAN_OPTIONS="detect_leaks=0:abort_on_error=1:handle_segv=1:log_path=$RUN/$TAG/asan:print_stacktrace=1"
  fi
  cd "$PREFIX"
  "$PREFIX/bin/httpd" -f "$RUN/${TAG}.conf" -DFOREGROUND > "$RUN/${TAG}/console.log" 2>&1 &
  local HPID=$!
  for i in $(seq 1 80); do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "http://127.0.0.1:$PORT/" 2>/dev/null || true)
    [ -n "$code" ] && [ "$code" != "000" ] && break
    sleep 0.25
  done
  local i
  for i in 1 2 3; do
    echo "--- attempt $i: GET multipart no body ---"
    curl -sS -v --max-time 5 -o "$RUN/${TAG}/body_$i.txt" \
      -H 'Content-Type: multipart/form-data; boundary=ABCXYZ' \
      "http://127.0.0.1:$PORT/parsebody" 2> "$RUN/${TAG}/curl_$i.txt" | head -5
    echo "curl_exit=$?"
    sleep 0.5
  done
  echo "--- POST Content-Length: 0 multipart ---"
  curl -sS -v --max-time 5 -o "$RUN/${TAG}/body_post0.txt" -X POST \
    -H 'Content-Type: multipart/form-data; boundary=ABCXYZ' \
    -H 'Content-Length: 0' "http://127.0.0.1:$PORT/parsebody" 2> "$RUN/${TAG}/curl_post0.txt" | head -3
  sleep 1
  echo "--- alive? ---"
  curl -s -o /dev/null -w 'after_http=%{http_code}\n' --max-time 2 "http://127.0.0.1:$PORT/" || echo "SERVER DEAD"
  echo "--- error_log tail ---"
  tail -25 "$RUN/${TAG}/error_log" 2>/dev/null
  echo "--- asan files ---"
  ls -l "$RUN/${TAG}"/asan.* 2>/dev/null && head -40 "$RUN/${TAG}"/asan.* 2>/dev/null
  kill $HPID 2>/dev/null; sleep 0.5; kill -9 $HPID 2>/dev/null
  unset ASAN_OPTIONS
}

run_case /opt/httpd plain 8095
run_case /opt/httpd-asan asan 8096
