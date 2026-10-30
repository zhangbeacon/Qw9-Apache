#!/bin/bash
# 用带 dladdr 的 memcpy 包装器证明：mod_lua 以 SIZE_MAX 调用 memcpy 并导致子进程终止
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
PREFIX=/opt/httpd
EVID="$ROOT/evidence/CVE-2021-44790"
cat > /tmp/logmemcpy2.c <<'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <stddef.h>
#include <dlfcn.h>
void *memcpy(void *d, const void *s, size_t n) {
    if (n > (1UL << 30)) {
        Dl_info info;
        void *ret = __builtin_return_address(0);
        char buf[512];
        int len;
        if (dladdr(ret, &info) && info.dli_fname) {
            len = snprintf(buf, sizeof buf,
                "[logmemcpy] HUGE memcpy n=%zu ret=%p module=%s base=%p off=0x%lx sym=%s\n",
                n, ret, info.dli_fname, info.dli_fbase,
                (unsigned long)((char *)ret - (char *)info.dli_fbase),
                info.dli_sname ? info.dli_sname : "?");
        } else {
            len = snprintf(buf, sizeof buf, "[logmemcpy] HUGE memcpy n=%zu ret=%p\n", n, ret);
        }
        if (len > 0) { ssize_t wr = write(2, buf, (size_t)len); (void)wr; }
        _exit(77);
    }
    for (size_t i = 0; i < n; i++) ((char *)d)[i] = ((const char *)s)[i];
    return d;
}
EOF
gcc -shared -fPIC -O1 -o /tmp/liblogmemcpy2.so /tmp/logmemcpy2.c -ldl 2>/dev/null
sed 's/Listen 8082/Listen 8083/; s/ServerName 127.0.0.1:8082/ServerName 127.0.0.1:8083/' \
  "$ROOT/conf/httpd-44790.conf" > "$PREFIX/conf/httpd-44790-logmemcpy.conf"
cp -f "$ROOT/conf/lua/parsebody.lua" "$PREFIX/lua/parsebody.lua"
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
sleep 0.7
cd "$PREFIX"; : > logs/error_log; : > logs/access_log
LD_PRELOAD=/tmp/liblogmemcpy2.so "$PREFIX/bin/httpd" -f "$PREFIX/conf/httpd-44790-logmemcpy.conf" \
  -DFOREGROUND > "$EVID/logmemcpy_console.log" 2>&1 &
HPID=$!
for i in $(seq 1 40); do curl -s -o /dev/null http://127.0.0.1:8083/ && break; sleep 0.25; done
check="${EVID}/lua_probe_response.txt"
curl -sS -o "$check" -w 'probe_http=%{http_code}\n' -X POST http://127.0.0.1:8083/parsebody \
  -H 'Content-Type: text/plain' --data x
python3 "$ROOT/poc/CVE-2021-44790/poc.py" 127.0.0.1 8083 /parsebody 3 > /dev/null 2>&1 || true
sleep 2
{
  echo "== 普通构建 /opt/httpd + LD_PRELOAD memcpy 观察器 =="
  "$PREFIX/bin/httpd" -v
  sha256sum "$PREFIX/bin/httpd"
  echo
  echo "== 服务端 error_log 中的 HUGE memcpy 记录 =="
  grep -a 'logmemcpy' logs/error_log
  echo
  echo "== 该次请求前后的 logger 记录 =="
  grep -a -E 'logmemcpy|dispatching parsebody|AH00051|Memory allocation' logs/error_log | tail -10
} > "$EVID/logmemcpy_huge_call.txt" 2>&1
cp -f logs/error_log "$EVID/logmemcpy_error_log.txt" 2>/dev/null || true
kill "$HPID" 2>/dev/null || true
sleep 0.5
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
echo "=== saved ==="; cat "$EVID/logmemcpy_huge_call.txt"
