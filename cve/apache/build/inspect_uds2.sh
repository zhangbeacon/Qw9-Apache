#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "== proxy_util 2580-2640 =="
sed -n '2570,2645p' modules/proxy/proxy_util.c
echo "== where uds_path used =="
grep -rn "uds_path" modules/proxy/*.c modules/proxy/*.h
echo "== autoconnect uds =="
sed -n '/static apr_status_t ap_proxy_connect_backend/,/^}/p' modules/proxy/proxy_util.c | grep -n -B3 -A6 'uds'
