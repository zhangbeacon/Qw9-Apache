#!/bin/bash
# 安装 httpd 2.4.49 构建依赖（WSL1 Ubuntu 22.04）
set -x
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo "waiting dpkg lock"; sleep 5; done
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
  libapr1-dev libaprutil1-dev libpcre2-dev liblua5.3-dev lua5.3 \
  build-essential curl netcat-openbsd libssl-dev zlib1g-dev libexpat1-dev
rc=$?
echo "APT_RC=$rc"
for p in libapr1-dev libaprutil1-dev libpcre2-dev liblua5.3-dev lua5.3; do
  dpkg -s "$p" >/dev/null 2>&1 && echo "OK $p" || echo "MISS $p"
done
exit $rc
