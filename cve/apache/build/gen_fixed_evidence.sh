#!/bin/bash
# 生成固定版负向对照的补充证据：
#  1) Ubuntu mod_lua 反汇编显示 2.4.53 修复的 *rbuf=NULL/*size=0
#  2) Ubuntu changelog/strings 显示 CVE-2024-38474 backport
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
EVID="$ROOT/evidence"
MOD=/usr/lib/apache2/modules/mod_lua.so

{
  echo "=== Ubuntu apache2 2.4.52-1ubuntu4.25 / mod_lua.so ==="
  /usr/sbin/apache2 -v
  dpkg-query -W -f='apache2-bin=${Version}\n' apache2-bin 2>/dev/null
  sha256sum "$MOD"
  echo
  echo "=== lua_read_body 反汇编（0xc310 起；调用 ap_setup_client_block 前） ==="
  echo "    c32a: movq   \$0x0,(%rsi)        <-- *rbuf = NULL   (2.4.53 fix)"
  echo "    c336: movq   \$0x0,(%rdx)        <-- *size = 0      (2.4.53 fix)"
  echo "    c33d: call   ap_setup_client_block@plt"
  objdump -d --no-show-raw-insn --start-address=0xc310 --stop-address=0xc350 "$MOD" 2>/dev/null
  echo
  echo "=== lua_write_body 反汇编（0xc42x；调用前 *size=0） ==="
  objdump -d --no-show-raw-insn --start-address=0xc420 --stop-address=0xc450 "$MOD" 2>/dev/null
} > "$EVID/CVE-2022-22719/fixed_2.4.52_disasm.txt" 2>&1

{
  echo "=== Ubuntu apache2-bin changelog 中的 CVE-2024-38474 backport ==="
  zgrep -inE 'CVE-2024-38474' /usr/share/doc/apache2-bin/changelog.Debian.gz 2>/dev/null | head -10
  echo
  echo "=== mod_rewrite.so 中的修复字符串 ==="
  strings /usr/lib/apache2/modules/mod_rewrite.so | grep -iE 'Unsafe URL with|UnsafeAllow3F|UnsafePrefixStat'
  echo
  echo "=== 版本 ==="
  /usr/sbin/apache2 -v
  dpkg-query -W -f='apache2-bin=${Version}\n' apache2-bin 2>/dev/null
} > "$EVID/CVE-2024-38474/fixed_2.4.52_changelog.txt" 2>&1

cat "$EVID/CVE-2022-22719/fixed_2.4.52_disasm.txt"
echo "================================================"
cat "$EVID/CVE-2024-38474/fixed_2.4.52_changelog.txt"
