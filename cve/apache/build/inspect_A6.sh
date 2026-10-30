#!/bin/bash
SRC=/root/work/miner/src/httpd-2.4.49
echo "=== ap_set_keepalive occurrences ==="
grep -rn "ap_set_keepalive" "$SRC" | head
echo
echo "=== ap_set_keepalive body ==="
F=$(grep -rl "AP_DECLARE(void) ap_set_keepalive" "$SRC"/server "$SRC"/modules 2>/dev/null | head -1)
echo "file=$F"
awk '/AP_DECLARE\(void\) ap_set_keepalive/{f=1} f{print NR": "$0} f&&/^}/{exit}' "$F"
echo
echo "=== ap_status_drops_connection ==="
grep -rn "ap_status_drops_connection" "$SRC"/server "$SRC"/include | head
F2=$(grep -rl "AP_DECLARE(int) ap_status_drops_connection" "$SRC"/server 2>/dev/null | head -1)
awk '/AP_DECLARE\(int\) ap_status_drops_connection/{f=1} f{print NR": "$0} f&&/^}/{exit}' "$F2"
echo
echo "=== ap_send_error_response discard-related lines ==="
sed -n '1370,1560p' "$SRC/modules/http/http_protocol.c"
