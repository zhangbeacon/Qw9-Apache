#!/bin/bash
# =============================================================================
# 修复版负向对照：Ubuntu 22.04 apache2 2.4.52-1ubuntu4.25
#
# 该发行版已回填 CVE-2022-37436.patch（mod_proxy_http，AH10404）与
# CVE-2023-27522.patch（mod_proxy_uwsgi 严格解析）。用与正面 PoC 完全相同的
# 恶意后端与请求，验证修复后：
#   - /nul 不再把后续安全头并入 body，而是 502；
#   - /oversize 不再 200+截断转发，而是 502；
#   - uwsgi 的 /cr、/badname 由模块层直接 502。
# 退出码 0 = 两个 CVE 的修复版行为均确认（负向对照通过）。
# =============================================================================
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
EVID="$ROOT/evidence/fixed_2.4.52_response"
APACHE2="/usr/sbin/apache2"
PORT=8092
HPID=""
BPID=""

cleanup() {
    if [ -n "$HPID" ]; then
        kill "$HPID" 2>/dev/null || true
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            kill -0 "$HPID" 2>/dev/null || break
            sleep 0.2
        done
        kill -9 "$HPID" 2>/dev/null || true
    fi
    if [ -n "$BPID" ]; then
        kill "$BPID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

mkdir -p "$EVID"
mkdir -p /tmp/fixed-2.4.52-www
chmod 755 /tmp/fixed-2.4.52-www
rm -f "$EVID"/* 2>/dev/null || true

echo "== [0] 修复版检查 =="
if [ ! -x "$APACHE2" ]; then
    echo "SKIP: $APACHE2 不存在"
    exit 2
fi
{
    "$APACHE2" -v
    sha256sum "$APACHE2" /usr/lib/apache2/modules/mod_proxy_http.so \
             /usr/lib/apache2/modules/mod_proxy_uwsgi.so
    strings /usr/lib/apache2/modules/mod_proxy_http.so | grep -E \
        'AH10404|Error reading headers|ResponseFieldSize' || true
} > "$EVID/00_fixed_version.txt" 2>&1

run_case() {
    local CASE="$1" CONF="$2" BPORT="$3" BACKEND="$4"
    echo "== [$CASE] 端口检查 8092/$BPORT =="
    python3 - "$PORT" "$BPORT" <<'PY'
import socket
import sys
for port in (int(sys.argv[1]), int(sys.argv[2])):
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        s.bind(("127.0.0.1", port))
    except OSError as exc:
        print("PORT %d BUSY: %r" % (port, exc))
        sys.exit(1)
    finally:
        s.close()
print("ports free")
PY
    if [ $? -ne 0 ]; then
        echo "FAIL: 端口被占用"
        return 1
    fi

    echo "== [$CASE] 启动恶意后端 :$BPORT =="
    python3 "$BACKEND" "$BPORT" > "$EVID/${CASE}_backend.log" 2>&1 &
    BPID=$!
    for _ in $(seq 1 40); do
        python3 - "$BPORT" <<'PY' >/dev/null 2>&1 && break
import socket
import sys
s = socket.create_connection(("127.0.0.1", int(sys.argv[1])), timeout=0.3)
s.close()
PY
        sleep 0.1
    done
    kill -0 "$BPID" 2>/dev/null || { echo "FAIL: backend 未启动"; BPID=""; return 1; }

    echo "== [$CASE] 启动修复版 httpd :$PORT =="
    : > "/tmp/fixed-2.4.52-${CASE}-error.log" 2>/dev/null || true
    : > "/tmp/fixed-2.4.52-${CASE}-access.log" 2>/dev/null || true
    cd /etc/apache2 || return 1
    "$APACHE2" -f "$CONF" -DFOREGROUND \
        > "$EVID/${CASE}_console.log" 2>&1 &
    HPID=$!
    local READY=0
    for _ in $(seq 1 80); do
        if curl -s -o /dev/null "http://127.0.0.1:$PORT/control"; then
            READY=1
            break
        fi
        kill -0 "$HPID" 2>/dev/null || break
        sleep 0.2
    done
    if [ "$READY" != 1 ]; then
        echo "FAIL: 修复版 httpd 未就绪"
        tail -30 "$EVID/${CASE}_console.log" 2>/dev/null
        kill "$HPID" 2>/dev/null || true
        kill "$BPID" 2>/dev/null || true
        HPID=""
        BPID=""
        return 1
    fi

    echo "== [$CASE] 负向探针 =="
    python3 "$ROOT/poc/fixed_2.4.52/negative_probe.py" "$CASE" "$PORT" "$EVID"
    local RC=$?
    cp -f "/tmp/fixed-2.4.52-${CASE}-error.log" "$EVID/${CASE}_error_log.txt" \
        2>/dev/null || true
    cp -f "/tmp/fixed-2.4.52-${CASE}-access.log" "$EVID/${CASE}_access_log.txt" \
        2>/dev/null || true
    kill "$HPID" 2>/dev/null || true
    HPID=""
    kill "$BPID" 2>/dev/null || true
    BPID=""
    sleep 0.3
    return "$RC"
}

run_case 37436 "$ROOT/conf/fixed-2.4.52-37436.conf" 8093 \
    "$ROOT/poc/CVE-2022-37436/backend.py"
RC1=$?
run_case 27522 "$ROOT/conf/fixed-2.4.52-27522.conf" 8094 \
    "$ROOT/poc/CVE-2023-27522/uwsgi_backend.py"
RC2=$?

{
    echo "fixed_37436_probe_rc=$RC1"
    echo "fixed_27522_probe_rc=$RC2"
    echo "--- 37436 error log (AH10124/AH10404) ---"
    grep -E 'AH10124|AH10404|AH01106' "$EVID/37436_error_log.txt" 2>/dev/null || true
    echo "--- 27522 access log ---"
    cat "$EVID/27522_access_log.txt" 2>/dev/null || true
} > "$EVID/verdict.txt"

echo "== 负向对照汇总 =="
cat "$EVID/verdict.txt"
cleanup
trap - EXIT INT TERM
if [ "$RC1" = 0 ] && [ "$RC2" = 0 ]; then
    echo "RESULT: NEGATIVE CONTROL PASS (fixed 2.4.52 rejects both CVEs)"
    exit 0
fi
echo "RESULT: NEGATIVE CONTROL FAIL"
exit 1
