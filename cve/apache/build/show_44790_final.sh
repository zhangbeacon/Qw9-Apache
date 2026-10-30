#!/bin/bash
E=/mnt/e/强网拟态/cve/apache/evidence/CVE-2021-44790
echo "=== files ==="; ls -la "$E"
echo "=== verdict ==="; cat "$E/verdict.txt"
echo "=== error log (crash lines) ==="; grep -n -E 'AH00051|Memory allocation|crit|lua_request|parsebody|Segmentation|Abort' "$E/error_log.txt" | tail -20
echo "=== console ==="; cat "$E/console.log"
echo "=== asan_report size ==="; stat -c%s "$E/asan_report.txt" 2>/dev/null
echo "=== asan_report head ==="; head -20 "$E/asan_report.txt" 2>/dev/null
echo "=== lua probe ==="; cat "$E/lua_probe_response.txt"
echo "=== poc stderr pad3 ==="; cat "$E/poc_pad3_stderr.txt"
echo "=== poc stderr pad0 ==="; cat "$E/poc_pad0_stderr.txt"
echo "=== access log ==="; cat "$E/access_log.txt"
echo "=== process_after ==="; cat "$E/process_after.txt"
