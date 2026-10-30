#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "===== bail_out_on_error ====="
sed -n '60,140p' modules/http/http_filters.c
echo "===== default_handler method checks ====="
grep -n "method_number\|M_GET\|HTTP_METHOD_NOT_ALLOWED" modules/generators/mod_???*.c 2>/dev/null | head
grep -n "AP_DECLARE(int) ap_setup_client_block" -A60 server/request.c | head -80
