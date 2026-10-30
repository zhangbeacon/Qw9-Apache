#!/bin/bash
cd /root/work/apache/httpd-2.4.49
echo "===== ap_status_drops_connection ====="
grep -rn "ap_status_drops_connection" server/ include/ | head
sed -n '/AP_DECLARE(int) ap_status_drops_connection/,/^}/p' server/protocol.c
echo "===== ap_discard_request_body (2.4.49) ====="
sed -n '/AP_DECLARE(int) ap_discard_request_body/,/^}/p' modules/http/http_filters.c
echo "===== ap_finalize_request_protocol ====="
sed -n '/AP_DECLARE(void) ap_finalize_request_protocol/,/^}/p' server/protocol.c
echo "===== error_output_stream/end_output_stream ====="
sed -n '/static void error_output_stream/,/^}/p' server/protocol.c
sed -n '/static void end_output_stream/,/^}/p' server/protocol.c
echo "===== ap_http_filter 413 ====="
grep -n "ENTITY_TOO_LARGE\|LimitRequestBody\|ap_get_limit_req_body" modules/http/http_filters.c server/core.c server/request.c | head -30
echo "===== proxy_detect 2.4.49 ====="
sed -n '/static int proxy_detect/,/^}/p' modules/proxy/mod_proxy.c
echo "===== ap_proxy_pre_request head ====="
sed -n '/PROXY_DECLARE(int) ap_proxy_pre_request/,/^}/p' modules/proxy/proxy_util.c | head -80
echo "===== normalize path 2.4.49 ====="
grep -n "ap_normalize_path" server/util.c
sed -n '/AP_DECLARE(int) ap_normalize_path/,/^}/p' server/util.c
