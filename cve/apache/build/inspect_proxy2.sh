#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "===== find get_worker ====="
grep -n "ap_proxy_get_worker" modules/proxy/proxy_util.c modules/proxy/mod_proxy.h | head
sed -n '1690,1790p' modules/proxy/proxy_util.c
echo "===== canon_netloc ====="
grep -rn "canon_netloc" modules/proxy/ include/ | head
echo "===== get_url_scheme ====="
sed -n '/static const char \*get_url_scheme/,/^}/p' modules/proxy/mod_proxy_http.c
echo "===== forward worker conf->forward creation ====="
grep -n "conf->forward\|forward =" modules/proxy/mod_proxy.c | head -10
echo "===== proxy_run_canon_handler order ====="
grep -n "proxy_run_canon_handler\|ap_proxy_canon" modules/proxy/mod_proxy.c | head
