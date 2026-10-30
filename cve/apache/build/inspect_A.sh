#!/bin/bash
# 子智能体 A：源码/环境检查
set -u
SRC=/root/work/miner/src/httpd-2.4.49
echo "=== httpd modules (subset) ==="
/opt/httpd/bin/httpd -l
echo
echo "=== LoadModule files ==="
for m in rewrite proxy proxy_http unixd authz_core authz_host log_config mime dir alias headers env setenvif autoindex; do
  ls -l /opt/httpd/modules/mod_${m}.so 2>/dev/null
done
echo
echo "=== running httpd/apache2 ==="
ps -ef | grep -E 'httpd|apache2' | grep -v grep || true
echo
echo "=== ports (ss or /proc) ==="
ss -ltn 2>/dev/null || true
echo
echo "=== 22720: ap_discard_request_body source 2.4.49 ==="
grep -n "ap_discard_request_body" "$SRC/server/protocol.c" "$SRC/modules/http/http_filters.c" 2>/dev/null
echo
echo "=== 22720: call sites ==="
grep -rn "ap_discard_request_body" "$SRC/server" "$SRC/modules" 2>/dev/null | head -20
echo
echo "=== 22720: discard function body (2.4.49) ==="
awk '/AP_DECLARE\(int\) ap_discard_request_body/{f=1} f{print NR": "$0} f&&/^}/{exit}' "$SRC/modules/http/http_filters.c"
echo
echo "=== 22720: keepalive handling in ap_read_request / ap_process_request ==="
grep -n "keepalive = AP_CONN_CLOSE\|AP_CONN_CLOSE\|ap_discard_request_body" "$SRC/server/protocol.c" | head -40
echo
echo "=== 25690: splitout_queryargs ==="
awk '/static void splitout_queryargs/{f=1} f{print NR": "$0} f&&/^}/{exit}' "$SRC/modules/mappers/mod_rewrite.c"
echo
echo "=== 25690: ap_scan_vchar_obstext existence ==="
grep -rn "ap_scan_vchar_obstext" "$SRC/server" "$SRC/include" | head
echo
echo "=== 25690: proxy canonicalization search forwarding ==="
sed -n '95,175p' "$SRC/modules/proxy/mod_proxy_http.c"
echo
echo "=== 42013: ap_normalize_path 2.4.49 ==="
sed -n '495,610p' "$SRC/server/util.c"
