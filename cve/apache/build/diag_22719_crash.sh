#!/bin/bash
# 诊断 CVE-2022-22719 崩溃型：ASAN httpd + keep-alive 悬垂指针触发
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RUN=/tmp/cve-2022-22719/asan
PREFIX=/opt/httpd-asan
PORT=8095
rm -rf "$RUN"; mkdir -p "$RUN" "$PREFIX/lua" "$PREFIX/htdocs"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
[ -f "$PREFIX/htdocs/index.html" ] || echo '<html>lab</html>' > "$PREFIX/htdocs/index.html"
sed -e "s#/opt/httpd#${PREFIX}#g" -e "s#Listen 8095#Listen $PORT#" \
    -e "s#/tmp/cve-2022-22719#${RUN}#g" \
    "$ROOT/conf/CVE-2022-22719.conf" > "$RUN/asan.conf"
cd "$PREFIX"
export ASAN_OPTIONS="detect_leaks=0:abort_on_error=1:handle_segv=1:log_path=$RUN/asan:print_stacktrace=1"
"$PREFIX/bin/httpd" -f "$RUN/asan.conf" -DFOREGROUND > "$RUN/console.log" 2>&1 &
HPID=$!
echo "asan_httpd_pid=$HPID"
for i in $(seq 1 80); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "http://127.0.0.1:$PORT/" 2>/dev/null || true)
  if [ -n "$code" ] && [ "$code" != "000" ]; then break; fi
  sleep 0.25
done
python3 "$ROOT/poc/CVE-2022-22719/crash_try.py" "$PORT"
sleep 2
echo "=== children alive? ==="
ps -o pid,stat,cmd -p "$HPID" --ppid "$HPID" 2>/dev/null || true
echo "=== error_log tail ==="
tail -25 "$RUN/error_log" 2>/dev/null
echo "=== asan reports ==="
ls -l "$RUN"/asan.* 2>/dev/null || echo "(no asan log)"
for f in "$RUN"/asan.*; do [ -f "$f" ] && { echo "--- $f ---"; head -60 "$f"; }; done
kill $HPID 2>/dev/null; sleep 1; kill -9 $HPID 2>/dev/null
