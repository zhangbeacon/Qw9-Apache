#!/bin/bash
# 一次性安装构建/复现依赖；使用校园 DNS 修复 WSL1 解析
set -e
printf 'nameserver 202.196.64.1\nnameserver 202.196.64.2\nnameserver 114.114.114.114\n' > /etc/resolv.conf
sed -i 's|^https://mirrors.aliyun.com|http://mirrors.aliyun.com|' /etc/apt/sources.list 2>/dev/null || true
apt-get update -o Acquire::Retries=3
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential libpcre2-dev libpcre3-dev libapr1-dev libaprutil1-dev \
  libxml2-dev libncurses-dev bison flex cmake nmap dnsutils iputils-ping \
  python3-scapy libcap-dev libsystemd-dev
echo "INSTALL_DONE rc=$?"
