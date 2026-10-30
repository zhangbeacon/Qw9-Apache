#!/bin/bash
SRC=/root/work/miner/src/httpd-2.4.49
echo "=== mod_reqtimeout keepalive/timeout handling ==="
grep -n "keepalive\|APR_TIMEUP\|HTTP_REQUEST_TIME_OUT\|ap_get_brigade\|return" "$SRC/modules/filters/mod_reqtimeout.c" | sed -n '1,80p'
echo
echo "=== ap_map_http_request_error body ==="
awk '/AP_DECLARE\(int\) ap_map_http_request_error/{f=1} f{print NR": "$0} f&&/^}/{exit}' "$SRC/modules/http/http_filters.c"
echo
echo "=== core input filter timeout return ==="
grep -n "APR_TIMEUP\|APR_ETIMEDOUT\|rv =" "$SRC/server/core_filters.c" | sed -n '1,50p'
echo
echo "=== modules dir: reqtimeout / headers / status ==="
ls /opt/httpd/modules/mod_reqtimeout.so /opt/httpd/modules/mod_status.so 2>&1
echo
echo "=== 2.4.53 CHANGES CVE entry ==="
grep -n "22720" -B3 -A3 /root/work/miner/src/httpd-2.4.53/CHANGES | head -30
