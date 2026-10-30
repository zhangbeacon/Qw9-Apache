#!/bin/bash
# 环境检查（子智能体 C / apache 2.4.49）
set -u
echo "== id =="; id; uname -a
echo "== os =="; head -3 /etc/os-release
echo "== gcc =="; gcc --version | head -1
echo "== packages =="
for p in libapr1-dev libaprutil1-dev libpcre2-dev libexpat1-dev zlib1g-dev libssl-dev liblua5.3-dev lua5.3; do
  if dpkg -s "$p" >/dev/null 2>&1; then echo "OK   $p $(dpkg-query -W -f='${Version}' $p)"; else echo "MISS $p"; fi
done
echo "== headers/libs =="
ls /usr/include/apr-1.0 2>/dev/null | head -3 || echo "no apr-1.0 headers"
ls /usr/include/apr-1.0/apr_version.h 2>/dev/null || true
ls /usr/lib/x86_64-linux-gnu/libapr* 2>/dev/null || true
ls /usr/include/lua* 2>/dev/null || true
echo "== ports =="
if command -v ss >/dev/null; then ss -ltn 2>/dev/null | grep -E ':8082|:8083' || echo "8082/8083 free (ss)"; fi
# WSL1 上 ss 因 netlink 不可用，解析 /proc/net/tcp
python3 - <<'PY'
import struct
def ports(path):
    out=[]
    try:
        for line in open(path).read().splitlines()[1:]:
            f=line.split()
            if f[3]!='0A': continue
            port=int(f[1].split(':')[1],16)
            out.append(port)
    except FileNotFoundError:
        pass
    return sorted(set(out))
print("listening tcp ports:", ports('/proc/net/tcp'))
PY
echo "== tarball =="; sha256sum /mnt/e/强网拟态/cve/_downloads/httpd-2.4.49.tar.gz
echo "== disk =="; df -h /root /mnt/e | tail -2
echo "== existing /opt/httpd =="; ls -la /opt/httpd 2>/dev/null | head -5 || echo none
