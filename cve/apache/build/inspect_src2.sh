#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "===== ap_status_drops_connection macro ====="
sed -n '550,585p' include/httpd.h
echo "===== http_filter 330-450 ====="
sed -n '330,450p' modules/http/http_filters.c
echo "===== http_filter 1180-1260 ====="
sed -n '1180,1260p' modules/http/http_filters.c
echo "===== filter 1540-1580 ====="
sed -n '1540,1580p' modules/http/http_filters.c
echo "===== ap_read_request keepalive / connection loop ====="
grep -n "keepalive = AP_CONN" server/protocol.c | head -20
sed -n '1560,1710p' server/protocol.c
