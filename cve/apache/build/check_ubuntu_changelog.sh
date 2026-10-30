#!/bin/bash
# 确认 Ubuntu apache2 2.4.52-1ubuntu4.25 的 Debian changelog 是否记录了 22719/23943/38474 backport
set -u
CH=/usr/share/doc/apache2-bin/changelog.Debian.gz
echo "=== changelog file ==="
ls -l "$CH" 2>/dev/null || ls -l /usr/share/doc/apache2/changelog.Debian.gz 2>/dev/null || true
for f in "$CH" /usr/share/doc/apache2/changelog.Debian.gz; do
  [ -f "$f" ] || continue
  echo "----- $f : CVE mentions -----"
  zgrep -inE 'CVE-2022-22719|CVE-2022-23943|CVE-2024-38474' "$f" 2>/dev/null | head -12
  echo "----- $f : recent 40 lines -----"
  zcat "$f" 2>/dev/null | head -40
done
echo "=== mod_lua symbols (local?) ==="
file /usr/lib/apache2/modules/mod_lua.so
nm /usr/lib/apache2/modules/mod_lua.so 2>&1 | head -3
echo "=== PLT call sites to ap_setup_client_block in mod_lua.so ==="
objdump -d --no-show-raw-insn /usr/lib/apache2/modules/mod_lua.so 2>/dev/null \
  | grep -n 'ap_setup_client_block' | head -10
