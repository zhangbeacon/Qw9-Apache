#!/bin/bash
# 用 LD_PRELOAD 的 memcpy 包装器观察 mod_lua 是否真的以 SIZE_MAX 调用 memcpy
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
PREFIX=/opt/httpd
EVID="$ROOT/evidence/CVE-2021-44790"
cat > /tmp/logmemcpy.c <<'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <stddef.h>
void *memcpy(void *d, const void *s, size_t n) {
    if (n > (1UL << 30)) {
        char buf[160];
        int len = snprintf(buf, sizeof buf,
            "[logmemcpy] HUGE memcpy n=%zu ret=%p\n", n, __builtin_return_address(0));
        write(2, buf, len > 0 ? (size_t)len : 0);
        _exit(77);
    }
    for (size_t i = 0; i < n; i++) ((char *)d)[i] = ((const char *)s)[i];
    return d;
}
EOF
gcc -shared -fPIC -O1 -o /tmp/liblogmemcpy.so /tmp/logmemcpy.c
sed 's/Listen 8082/Listen 8083/; s/ServerName 127.0.0.1:8082/ServerName 127.0.0.1:8083/' \
  "$ROOT/conf/httpd-44790.conf" > "$PREFIX/conf/httpd-44790-logmemcpy.conf"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
sleep 0.7
cd "$PREFIX"
LD_PRELOAD=/tmp/liblogmemcpy.so "$PREFIX/bin/httpd" -f "$PREFIX/conf/httpd-44790-logmemcpy.conf" \
  -DFOREGROUND > "$EVID/logmemcpy_console.log" 2>&1 &
HPID=$!
for i in $(seq 1 40); do curl -s -o /dev/null http://127.0.0.1:8083/ && break; sleep 0.25; done
curl -sS -o /dev/null -w 'probe http=%{http_code}\n' -X POST http://127.0.0.1:8083/parsebody -H 'Content-Type: text/plain' --data x
python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8083 /parsebody 3 > /dev/null 2>&1 || true
sleep 2
echo "== logmemcpy console =="; cat "$EVID/logmemcpy_console.log"
echo "== error log tail =="; tail -6 "$PREFIX/logs/error_log"
kill "$HPID" 2>/dev/null || true
sleep 0.5
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
