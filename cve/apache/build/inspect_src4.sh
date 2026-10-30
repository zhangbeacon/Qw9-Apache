#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "===== ap_set_keepalive callers ====="
grep -rn "ap_set_keepalive" server/ modules/ include/ | head
echo "===== ap_set_keepalive body ====="
sed -n '/AP_DECLARE(void) ap_set_keepalive/,/^}/p' server/protocol.c
echo "===== ap_read_request tail ====="
sed -n '1500,1600p' server/protocol.c
echo "===== mod_lua set status support ====="
grep -n "r->status\|lua_ap_status\|status" modules/lua/lua_request.c | head -20
echo "===== mod_lua handler registration ====="
grep -n "LuaMapHandler\|lua-script\|handler" modules/lua/mod_lua.c | head -30
