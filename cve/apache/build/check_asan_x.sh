#!/bin/bash
E=/mnt/e/强网拟态/cve/apache/evidence/CVE-2021-44790
echo "=== poc stderr ==="; cat "$E/asan_x_poc_stderr.txt"
echo "=== poc resp ==="; cat "$E/asan_x_poc_response.txt"
echo "=== access log ==="; cat /opt/httpd-asan/logs/access_log 2>/dev/null | tail -5
echo "=== error log tail ==="; tail -20 /opt/httpd-asan/logs/error_log 2>/dev/null
echo "=== asan logs ==="; ls -l /opt/httpd-asan/logs/asan.* 2>/dev/null
echo "=== process ==="; ps -ef | grep -F /opt/httpd-asan/bin/httpd | grep -v grep
