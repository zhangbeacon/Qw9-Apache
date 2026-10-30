#!/bin/bash
# 诊断：dump 运行期 per-directory 配置，确认 CVE-2024-38474 的 <Directory> 是否生效
CONF="/mnt/e/强网拟态/cve/apache/conf/CVE-2024-38474.conf"
/opt/httpd/bin/httpd -t -D DUMP_RUN_CFG -f "$CONF" > /tmp/cve-2024-38474/run_cfg.txt 2>&1
echo "exit=$?"
wc -l /tmp/cve-2024-38474/run_cfg.txt
grep -n 'lab/upload' -A6 -B2 /tmp/cve-2024-38474/run_cfg.txt | head -80
echo "=== options lines ==="
grep -n 'ExecCGI' /tmp/cve-2024-38474/run_cfg.txt | head -20
