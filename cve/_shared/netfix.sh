#!/bin/bash
# 修复 WSL1 的 DNS（校园 DNS 可用，公网 DNS 被墙），并自检外网连通性
set -e
printf 'nameserver 202.196.64.1\nnameserver 202.196.64.2\nnameserver 114.114.114.114\n' > /etc/resolv.conf
echo "[net] resolv.conf 已设置"
getent hosts github.com >/dev/null && echo "[net] DNS OK" || echo "[net] DNS FAIL"
curl -sS -o /dev/null -m 15 -w '[net] github:%{http_code}\n' https://raw.githubusercontent.com/apache/httpd/2.4.49/README || true
