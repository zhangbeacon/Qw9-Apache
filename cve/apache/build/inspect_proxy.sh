#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "===== ap_proxy_de_socketfy ====="
grep -rn "ap_proxy_de_socketfy" modules/proxy/*.c modules/proxy/*.h | head
sed -n '/char \*ap_proxy_de_socketfy/,/^}/p' modules/proxy/proxy_util.c
echo "===== fix_uds_filename ====="
sed -n '/static int fix_uds_filename/,/^}/p' modules/proxy/proxy_util.c
echo "===== ap_proxy_get_worker_ex ====="
sed -n '/PROXY_DECLARE(proxy_worker \*)ap_proxy_get_worker_ex/,/^}/p' modules/proxy/proxy_util.c
echo "===== proxy_http_canon / hostname usage ====="
grep -n "parsed_uri.hostname\|ap_proxy_canon_netloc\|proxy_canon" modules/proxy/mod_proxy_http.c | head -20
sed -n '/static int proxy_http_canon/,/^}/p' modules/proxy/mod_proxy_http.c
echo "===== ap_proxy_canon_netloc ====="
sed -n '/PROXY_DECLARE(char \*)ap_proxy_canon_netloc/,/^}/p' modules/proxy/proxy_util.c
