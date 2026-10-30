#!/bin/bash
E=/mnt/e/强网拟态/cve/apache/evidence/CVE-2021-44790
echo "=== asan_report_pad3.txt (hexdump-ish) ==="
cat "$E/asan_report_pad3.txt" 2>/dev/null; echo "[size=$(stat -c%s "$E/asan_report_pad3.txt" 2>/dev/null)]"
echo "=== console_asan_pad3.log ==="
cat "$E/console_asan_pad3.log" 2>/dev/null
echo "=== console_asan_pad0.log ==="
cat "$E/console_asan_pad0.log" 2>/dev/null
echo "=== poc_stderr_asan_pad3 ==="
cat "$E/poc_stderr_asan_pad3.txt" 2>/dev/null
echo "=== poc_response_asan_pad3 ==="
cat "$E/poc_response_asan_pad3.txt" 2>/dev/null
echo "=== /opt/httpd-asan/logs/asan.* ==="
ls -l /opt/httpd-asan/logs/asan.* 2>/dev/null
echo "=== core files ==="
ls -l /opt/httpd-asan/core* /opt/httpd-asan/logs/core* 2>/dev/null || echo none
