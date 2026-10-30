#!/bin/bash
set -u
ROOT=/root/work/miner
for v in 2.4.54 2.4.59; do
  f=httpd-$v.tar.gz
  [ -d "$ROOT/src/httpd-$v" ] && { echo "skip $v"; continue; }
  for url in "https://repo.huaweicloud.com/apache/httpd/$f" "https://archive.apache.org/dist/httpd/$f"; do
    if curl -sSL --retry 2 -m 600 -o "$ROOT/dl/$f" "$url" && tar tzf "$ROOT/dl/$f" >/dev/null 2>&1; then
      tar xzf "$ROOT/dl/$f" -C "$ROOT/src" && echo "OK $v"; break
    fi
  done
done
ls -d "$ROOT/src"/httpd-*
