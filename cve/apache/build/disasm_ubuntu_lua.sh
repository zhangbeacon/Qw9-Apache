#!/bin/bash
# 反汇编 Ubuntu mod_lua.so 的两个 ap_setup_client_block 调用点，检查是否在调用前
# 对 *rbuf / *size 做了 NULL/0 初始化（2.4.53 修复的特征）
set -u
MOD=/usr/lib/apache2/modules/mod_lua.so
echo "=== call site 1 (lua_read_body?) 0xc2c0-0xc360 ==="
objdump -d --no-show-raw-insn --start-address=0xc2b0 --stop-address=0xc360 "$MOD" 2>/dev/null
echo "=== call site 2 (lua_write_body?) 0xc3c0-0xc460 ==="
objdump -d --no-show-raw-insn --start-address=0xc3c0 --stop-address=0xc460 "$MOD" 2>/dev/null
