#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "===== ap_set_keepalive ====="
sed -n '/AP_DECLARE(int) ap_set_keepalive/,/^}/p' modules/http/http_protocol.c
echo "===== caller context http_filters 1400-1440 ====="
sed -n '1400,1440p' modules/http/http_filters.c
echo "===== ap_send_error_response status/keepalive ====="
grep -n "ap_set_keepalive\|keepalive" modules/http/http_protocol.c | head -20
