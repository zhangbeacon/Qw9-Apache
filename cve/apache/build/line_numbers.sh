#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "== 41773 =="
grep -n "AP_DECLARE(int) ap_normalize_path" server/util.c
grep -n "path\[l + 1\] == '\.'" server/util.c
grep -n "second dot" server/util.c
echo "== 44224 =="
grep -n "static int proxy_detect" modules/proxy/mod_proxy.c
grep -n "conf->req && r->parsed_uri.scheme" modules/proxy/mod_proxy.c
grep -n "url = ap_proxy_de_socketfy" modules/proxy/proxy_util.c
grep -n "static int fix_uds_filename" modules/proxy/proxy_util.c
grep -n "PROXY_DECLARE(int) ap_proxy_pre_request" modules/proxy/proxy_util.c
grep -n "fix_uds_filename(r, url)" modules/proxy/proxy_util.c
grep -n "AP_DECLARE(int) ap_read_request" server/protocol.c
grep -n "ap_run_post_read_request" server/protocol.c
echo "== 44790 =="
grep -n "static int req_parsebody" modules/lua/lua_request.c
grep -n "vlen = end - crlf - 8" modules/lua/lua_request.c
grep -n "memcpy(buffer, crlf + 4, vlen)" modules/lua/lua_request.c
grep -n "ap_lua_binstrstr(crlf" modules/lua/lua_request.c
echo "== 41773 scriptalias ==="
grep -n "ScriptAlias" docs/conf/httpd.conf | head -3
echo "== 44224 build modules =="
/opt/httpd/bin/httpd -M 2>/dev/null | grep -E 'proxy|cgid|lua'
