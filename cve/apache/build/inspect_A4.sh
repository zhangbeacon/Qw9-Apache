#!/bin/bash
SRC=/root/work/miner/src/httpd-2.4.49
echo "=== bail_out_on_error full ==="
sed -n '82,135p' "$SRC/modules/http/http_filters.c"
echo
echo "=== ap_set_keepalive ==="
awk '/AP_DECLARE\(void\) ap_set_keepalive/{f=1} f{print NR": "$0} f&&/^}/{exit}' "$SRC/modules/http/http_protocol.c"
echo
echo "=== ap_send_error_response (discard / keepalive parts) ==="
grep -n "ap_send_error_response" "$SRC/modules/http/http_protocol.c"
sed -n '1900,2100p' "$SRC/modules/http/http_protocol.c" | grep -n "discard\|keepalive\|status" 
echo
echo "=== ap_die ==="
awk '/AP_DECLARE\(void\) ap_die/{f=1} f{print NR": "$0} f&&/^}/{exit}' "$SRC/modules/http/http_protocol.c"
echo
echo "=== rewrite backref substitution ==="
grep -n "ap_pregsub\|pregsub" "$SRC/modules/mappers/mod_rewrite.c" | head -20
echo
echo "=== apply_rewrite_rule ==="
sed -n '4000,4120p' "$SRC/modules/mappers/mod_rewrite.c"
