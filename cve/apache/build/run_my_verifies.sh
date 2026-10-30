#!/bin/bash
# 子智能体 C：三个 CVE 的 verify 最终复核（顺序执行，记录退出码/端口/残留进程）
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
chmod +x "$ROOT/poc/CVE-2024-38474/verify.sh" \
         "$ROOT/poc/CVE-2022-22719/verify.sh" \
         "$ROOT/poc/CVE-2022-23943/verify.sh"
echo "=== ports before ==="
ss -ltn 2>/dev/null | grep -E ':809[56]|:810[3-5]' || echo PORTS_FREE

bash "$ROOT/poc/CVE-2024-38474/verify.sh" > /tmp/v38474.log 2>&1
E1=$?
echo "CVE-2024-38474_EXIT=$E1"

bash "$ROOT/poc/CVE-2022-22719/verify.sh" > /tmp/v22719.log 2>&1
E2=$?
echo "CVE-2022-22719_EXIT=$E2"

bash "$ROOT/poc/CVE-2022-23943/verify.sh" > /tmp/v23943.log 2>&1
E3=$?
echo "CVE-2022-23943_EXIT=$E3"

echo "=== tail of each log ==="
for f in /tmp/v38474.log /tmp/v22719.log /tmp/v23943.log; do
  echo "----- $f -----"
  tail -6 "$f"
done
echo "=== ports after ==="
ss -ltn 2>/dev/null | grep -E ':809[56]|:810[3-5]' || echo PORTS_FREE_AFTER
echo "=== my httpd/valgrind leftovers ==="
ps -ef | grep -E '/opt/httpd(-asan)?/bin/httpd|valgrind.*httpd' | grep -v grep || echo NO_LEFTOVERS
