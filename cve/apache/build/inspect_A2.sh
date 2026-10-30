#!/bin/bash
SRC=/root/work/miner/src/httpd-2.4.49
echo "=== core.c around 4840-4895 ==="
sed -n '4840,4895p' "$SRC/server/core.c"
echo
echo "=== protocol.c around 1660-1710 ==="
sed -n '1660,1715p' "$SRC/server/protocol.c"
echo
echo "=== protocol.c around 1500-1600 (keepalive / request cleanup) ==="
sed -n '1500,1600p' "$SRC/server/protocol.c"
echo
echo "=== ap_map_http_request_error ==="
grep -n "ap_map_http_request_error" -A30 "$SRC/server/protocol.c" | head -60
echo
echo "=== ap_http_filter chunked error paths ==="
grep -n "ap_http_filter\|HTTP_BAD_REQUEST\|ap_map_http_request_error\|bad chunk\|chunk" "$SRC/modules/http/http_filters.c" | sed -n '1,80p'
echo
echo "=== mod_proxy_http: r->args / search usage and request line ==="
grep -n "r->args\|search" "$SRC/modules/proxy/mod_proxy_http.c" | head -40
echo
echo "=== mod_rewrite: hook_uri2file initial uri/filename ==="
grep -n "r->filename\|r->uri\|r->args" "$SRC/modules/mappers/mod_rewrite.c" | sed -n '1,60p'
