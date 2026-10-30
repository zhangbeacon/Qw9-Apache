#!/bin/bash
# 检查本机 Ubuntu apache2 (2.4.52-1ubuntu4.25) 是否已 backport CVE-2024-38474 / 22719 / 23943 修复
set -u
echo "=== version ==="
/usr/sbin/apache2 -v 2>&1 || true
dpkg-query -W apache2-bin 2>/dev/null || true
echo "=== modules dir ==="
ls /usr/lib/apache2/modules/ 2>/dev/null | grep -E 'rewrite|sed|lua' || true
echo "=== mod_rewrite strings: UnsafeAllow3F / %3f ==="
strings /usr/lib/apache2/modules/mod_rewrite.so 2>/dev/null | grep -iE 'unsafe|%3f' || echo "(none)"
echo "=== mod_sed strings ==="
strings /usr/lib/apache2/modules/mod_sed.so 2>/dev/null | head -3 || echo "(no mod_sed)"
echo "=== mod_lua present? ==="
ls -l /usr/lib/apache2/modules/mod_lua.so 2>/dev/null || echo "(no mod_lua)"
echo "=== candidate config dirs ==="
ls /etc/apache2 2>/dev/null | head || true
