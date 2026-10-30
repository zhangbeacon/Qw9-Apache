#!/bin/bash
A=/root/work/miner/src/httpd-2.4.49
B=/root/work/miner/src/httpd-2.4.52
C=/root/work/miner/src/httpd-2.4.53
echo "=== diff 2.4.49 vs 2.4.52: http_filters.c (discard/bail) ==="
diff -u "$A/modules/http/http_filters.c" "$B/modules/http/http_filters.c" | sed -n '1,120p'
echo
echo "=== diff 2.4.52 vs 2.4.53: http_filters.c ==="
diff -u "$B/modules/http/http_filters.c" "$C/modules/http/http_filters.c" | sed -n '1,160p'
echo
echo "=== diff 2.4.52 vs 2.4.53: server/protocol.c ==="
diff -u "$B/server/protocol.c" "$C/server/protocol.c" | sed -n '1,200p'
echo
echo "=== grep ap_set_keepalive location ==="
grep -rn "AP_DECLARE(void) ap_set_keepalive" "$A"/server "$A"/modules | head
