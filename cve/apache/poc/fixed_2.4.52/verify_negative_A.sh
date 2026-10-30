#!/bin/bash
# =============================================================================
# 修复版负向对照：Ubuntu 22.04 Apache/2.4.52 (Ubuntu)（2.4.52-1ubuntu4.25，
# 含 42013/22720/25690 的发行版安全回移）
#
# 对子智能体 A 的三个 CVE 复测同一组 PoC，期望全部不再命中：
#   CVE-2021-42013 : 单层/双重编码穿越均应为 400 Bad Request，读不到 /etc/passwd
#   CVE-2023-25690 : 恶意 RewriteRule 请求应为 403（Backend 收不到被拆分的请求）
#   CVE-2022-22720 : 丢弃请求体超时应返回 408 且 Connection: close，第二个请求不被处理
#
# 退出码 0 = 三个 CVE 在修复版上均不再命中（负向对照通过）
# 只使用 8090/8091 与自己的进程组，不 pkill 全局进程。
# =============================================================================
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
EVID="$ROOT/evidence/fixed_2.4.52_A"
RT=/tmp/apacheA/neg
BIN=/usr/sbin/apache2
MODS=/usr/lib/apache2/modules
PORT=8090
BACKPORT=8091
BASE="http://127.0.0.1:$PORT"
HPID=""
BPID=""

mkdir -p "$EVID" "$RT"
rm -f "$EVID"/*.txt "$EVID"/*.log 2>/dev/null || true

cleanup() {
  if [ -n "$HPID" ]; then
    kill -TERM -- -"$HPID" 2>/dev/null || kill -TERM "$HPID" 2>/dev/null || true
  fi
  if [ -n "$BPID" ]; then kill -TERM "$BPID" 2>/dev/null || true; fi
  sleep 0.4
  if [ -n "$HPID" ]; then kill -KILL -- -"$HPID" 2>/dev/null || kill -KILL "$HPID" 2>/dev/null || true; fi
  if [ -n "$BPID" ]; then kill -KILL "$BPID" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

prep() { # $1=src $2=dst $3=tag
  rm -rf "$RT/$3"
  mkdir -p "$RT/$3"
  sed -e 's#^LoadModule unixd_module.*#\# unixd is static in Ubuntu build#' \
      -e 's#^LoadModule log_config_module.*#\# log_config is static in Ubuntu build#' \
      -e "s#modules/#$MODS/#g" \
      -e "s#/tmp/apacheA/#$RT/#g" \
      "$1" > "$2"
  sed -i "1i LoadModule mpm_event_module $MODS/mod_mpm_event.so" "$2"
  sed -i "1i DefaultRuntimeDir $RT/$3" "$2"
}

wait_up() {
  for i in $(seq 1 80); do
    if curl -s -o /dev/null --max-time 1 "$BASE/"; then return 0; fi
    sleep 0.2
  done
  return 1
}

[ -x "$BIN" ] || { echo "未发现 $BIN"; exit 2; }

echo "== [0] 修复版信息 =="
{
  echo "== 修复版二进制 =="
  "$BIN" -v
  sha256sum "$BIN"
  dpkg-query -W -f='apache2-bin=${Version}\n' apache2-bin 2>/dev/null
  echo
  echo "== 说明 =="
  echo "Ubuntu 22.04 发行版 2.4.52-1ubuntu4.25（含 CVE-2021-42013/2022-22720/2023-25690 安全回移）"
  echo "对比目标：自编译 pristine Apache/2.4.49（/opt/httpd）"
} > "$EVID/00_version_build.txt" 2>&1

echo "== [1] CVE-2021-42013 负向 =="
prep "$ROOT/conf/CVE-2021-42013.conf" "$RT/42013.conf" 42013
cd "$RT/42013" || exit 2
setsid "$BIN" -f "$RT/42013.conf" -DFOREGROUND > "$RT/42013/console.log" 2>&1 &
HPID=$!
wait_up || { echo "START FAILED"; tail -20 "$RT/42013/console.log"; exit 2; }
{
  echo "== Apache/2.4.52 (Ubuntu) negative control for CVE-2021-42013 =="
  "$BIN" -v
  echo
  echo "== single encoded (.%2e) =="
  curl -sS -i --path-as-is "$BASE/icons/.%2e/.%2e/.%2e/.%2e/etc/passwd" | head -14
  echo
  echo "== double encoded (.%%32%65) =="
  curl -sS -i --path-as-is "$BASE/icons/.%%32%65/.%%32%65/.%%32%65/.%%32%65/etc/passwd" | head -14
  echo
  echo "== server error_log =="
  cat "$RT/42013/error_log" 2>/dev/null | tail -10
} > "$EVID/42013_negative.txt" 2>&1
R1=0
grep -q 'root:x:0:0' "$EVID/42013_negative.txt" && R1=1
kill -TERM -- -"$HPID" 2>/dev/null || true; sleep 0.5; kill -KILL -- -"$HPID" 2>/dev/null || true; HPID=""
echo "42013 fixed_hit(should 0)=$R1"

echo "== [2] CVE-2023-25690 负向 =="
rm -rf "$RT/25690"; mkdir -p "$RT/25690"
python3 "$ROOT/poc/CVE-2023-25690/backend.py" "$RT/25690/backend.log" "$BACKPORT" \
  > "$RT/25690/backend_console.log" 2>&1 &
BPID=$!
for i in $(seq 1 30); do
  python3 - "$BACKPORT" <<'PY' && break
import socket, sys
s = socket.socket(); s.settimeout(0.2)
try:
    s.connect(("127.0.0.1", int(sys.argv[1])))
finally:
    s.close()
PY
  sleep 0.1
done
prep "$ROOT/conf/CVE-2023-25690.conf" "$RT/25690.conf" 25690
cd "$RT/25690" || exit 2
setsid "$BIN" -f "$RT/25690.conf" -DFOREGROUND > "$RT/25690/console.log" 2>&1 &
HPID=$!
wait_up || { echo "START FAILED"; tail -20 "$RT/25690/console.log"; exit 2; }
{
  echo "== Apache/2.4.52 (Ubuntu) negative control for CVE-2023-25690 =="
  "$BIN" -v
  echo
  python3 "$ROOT/poc/CVE-2023-25690/probe.py" "$PORT" smuggle "$RT/25690/client_smuggle.txt"
  sleep 0.5
  echo
  echo "== backend log =="
  cat "$RT/25690/backend.log" 2>/dev/null
  echo
  echo "== server error_log =="
  tail -20 "$RT/25690/error_log" 2>/dev/null
} > "$EVID/25690_negative.txt" 2>&1
R2=0
grep -q 'REQUEST_LINES=2' "$RT/25690/backend.log" 2>/dev/null && R2=1
grep -q 'GET /injected' "$RT/25690/backend.log" 2>/dev/null && R2=1
grep -q 'BACKEND_SAW_2_REQUEST_LINE' "$EVID/25690_negative.txt" 2>/dev/null && R2=1
kill -TERM -- -"$HPID" 2>/dev/null || true; sleep 0.5; kill -KILL -- -"$HPID" 2>/dev/null || true; HPID=""
kill -TERM "$BPID" 2>/dev/null || true; kill -KILL "$BPID" 2>/dev/null || true; BPID=""
echo "25690 fixed_hit(should 0)=$R2"

echo "== [3] CVE-2022-22720 负向 =="
prep "$ROOT/conf/CVE-2022-22720.conf" "$RT/22720.conf" 22720
mkdir -p "$RT/22720/htdocs/denied"
printf '<html><body>index</body></html>\n' > "$RT/22720/htdocs/index.html"
printf 'SMUGGLED_SECOND_REQUEST\n' > "$RT/22720/htdocs/smuggled.html"
cd "$RT/22720" || exit 2
setsid "$BIN" -f "$RT/22720.conf" -DFOREGROUND > "$RT/22720/console.log" 2>&1 &
HPID=$!
wait_up || { echo "START FAILED"; tail -20 "$RT/22720/console.log"; exit 2; }
{
  echo "== Apache/2.4.52 (Ubuntu) negative control for CVE-2022-22720 =="
  "$BIN" -v
  echo
  python3 "$ROOT/poc/CVE-2022-22720/probe.py" "$PORT" timeout403 "$RT/22720/client_timeout403.txt"
  sleep 0.5
  echo
  echo "== server access_log =="
  cat "$RT/22720/access_log" 2>/dev/null
  echo
  echo "== server error_log =="
  tail -20 "$RT/22720/error_log" 2>/dev/null
} > "$EVID/22720_negative.txt" 2>&1
R3=0
grep -q 'resp2_body_smuggled=True' "$EVID/22720_negative.txt" 2>/dev/null && R3=1
grep -q 'resp2_has_200=True' "$EVID/22720_negative.txt" 2>/dev/null && R3=1
kill -TERM -- -"$HPID" 2>/dev/null || true; sleep 0.5; kill -KILL -- -"$HPID" 2>/dev/null || true; HPID=""
echo "22720 fixed_hit(should 0)=$R3"

cat > "$EVID/verdict.txt" <<EOF
fixed_version=Apache/2.4.52 (Ubuntu) 2.4.52-1ubuntu4.25
42013_fixed_hit=$R1
25690_fixed_hit=$R2
22720_fixed_hit=$R3
note=0 表示修复版不再命中；三个值均为 0 则负向对照通过
EOF

echo
echo "===== summary (0 = fix effective) ====="
echo "42013_fixed_hit=$R1"
echo "25690_fixed_hit=$R2"
echo "22720_fixed_hit=$R3"
if [ "$R1" = 0 ] && [ "$R2" = 0 ] && [ "$R3" = 0 ]; then
  echo "RESULT: NEGATIVE CONTROL PASS (42013/25690/22720 all fixed on 2.4.52 Ubuntu)"
  exit 0
else
  echo "RESULT: NEGATIVE CONTROL FAIL"
  exit 1
fi
