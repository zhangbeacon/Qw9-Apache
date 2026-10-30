#!/bin/bash
# ASAN 构建上分别尝试 pad=3 / pad=0
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
PREFIX=/opt/httpd-asan
EVID="$ROOT/evidence/CVE-2021-44790"
mkdir -p "$PREFIX/conf" "$PREFIX/lua" "$PREFIX/logs" "$PREFIX/htdocs" "$EVID"
sed 's#/opt/httpd#/opt/httpd-asan#g; s/Listen 8082/Listen 8083/; s/ServerName 127.0.0.1:8082/ServerName 127.0.0.1:8083/' \
  "$ROOT/conf/httpd-44790.conf" > "$PREFIX/conf/httpd-44790-test.conf"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
echo '<html>asan</html>' > "$PREFIX/htdocs/index.html"

run_case() {
  local pad="$1"
  pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
  sleep 0.7
  rm -f "$PREFIX"/logs/asan.*
  : > "$PREFIX/logs/error_log"
  export ASAN_OPTIONS="detect_leaks=0:abort_on_error=0:handle_segv=1:log_path=$PREFIX/logs/asan:print_stacktrace=1"
  cd "$PREFIX"
  "$PREFIX/bin/httpd" -f "$PREFIX/conf/httpd-44790-test.conf" -DFOREGROUND > "$EVID/console_asan_pad$pad.log" 2>&1 &
  local hpid=$!
  for i in $(seq 1 60); do curl -s -o /dev/null http://127.0.0.1:8083/ && break; sleep 0.25; done
  echo "===== case pad=$pad httpd=$hpid children=$(pgrep -P $hpid | tr '\n' ' ') ====="
  curl -sS -o /dev/null -w 'lua-probe http=%{http_code}\n' -X POST http://127.0.0.1:8083/parsebody -H 'Content-Type: text/plain' --data 'x'
  python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8083 /parsebody "$pad" > "$EVID/poc_response_asan_pad$pad.txt" 2> "$EVID/poc_stderr_asan_pad$pad.txt" || true
  sleep 2
  echo "children_after=$(pgrep -P $hpid | tr '\n' ' ')"
  echo "--- asan files ---"; ls -l "$PREFIX"/logs/asan.* 2>/dev/null || echo none
  cat "$PREFIX"/logs/asan.* > "$EVID/asan_report_pad$pad.txt" 2>/dev/null || true
  echo "--- asan head ---"; head -30 "$EVID/asan_report_pad$pad.txt" 2>/dev/null
  echo "--- error tail ---"; tail -6 "$PREFIX/logs/error_log"
  kill "$hpid" 2>/dev/null || true
  sleep 0.5
  pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
}

run_case 3
run_case 0
