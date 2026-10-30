#!/bin/bash
SRC=/root/work/miner/src/httpd-2.4.49
echo "=== ap_set_keepalive 217-330 ==="
sed -n '217,330p' "$SRC/modules/http/http_protocol.c"
echo
echo "=== ap_status_drops_connection macro ==="
sed -n '545,575p' "$SRC/include/httpd.h"
echo
echo "=== http_filters.c around 1200-1260 (HTTP_BAD_REQUEST return) ==="
sed -n '1180,1260p' "$SRC/modules/http/http_filters.c"
echo
echo "=== 2.4.49 bail_out keepalive already? grep ==="
grep -n "disable keep-alive" -B5 -A5 "$SRC/modules/http/http_filters.c"
