#!/bin/bash
# 下载 Apache httpd 各修复版本源码（用于补丁差分挖掘）
set -u
bash /mnt/e/强网拟态/cve/_shared/netfix.sh >/dev/null 2>&1
ROOT=/root/work/miner
mkdir -p "$ROOT/dl" "$ROOT/src"

# 2.4.49 已有，直接复用
if [ -f /mnt/e/强网拟态/cve/_downloads/httpd-2.4.49.tar.gz ] && [ ! -d "$ROOT/src/httpd-2.4.49" ]; then
  cp /mnt/e/强网拟态/cve/_downloads/httpd-2.4.49.tar.gz "$ROOT/dl/"
  tar xzf "$ROOT/dl/httpd-2.4.49.tar.gz" -C "$ROOT/src"
  echo "OK   2.4.49 (local copy)"
fi

for v in 2.4.50 2.4.51 2.4.52 2.4.53 2.4.55 2.4.56 2.4.60; do
  f=httpd-$v.tar.gz
  if [ -d "$ROOT/src/httpd-$v" ]; then echo "skip $v (extracted)"; continue; fi
  if [ ! -s "$ROOT/dl/$f" ] || ! tar tzf "$ROOT/dl/$f" >/dev/null 2>&1; then
    ok=0
    for url in \
      "https://repo.huaweicloud.com/apache/httpd/$f" \
      "https://mirrors.tuna.tsinghua.edu.cn/apache/httpd/$f" \
      "https://archive.apache.org/dist/httpd/$f"; do
      echo "try $url"
      if curl -sSL --retry 2 --retry-delay 3 -m 900 -o "$ROOT/dl/$f" "$url" && tar tzf "$ROOT/dl/$f" >/dev/null 2>&1; then
        ok=1; break
      fi
    done
    if [ "$ok" != 1 ]; then echo "FAIL $v"; continue; fi
  fi
  tar xzf "$ROOT/dl/$f" -C "$ROOT/src" && echo "OK   $v ($(stat -c%s "$ROOT/dl/$f") bytes)"
done

echo "=== extracted versions ==="
ls -d "$ROOT/src"/httpd-* 2>/dev/null
echo DONE
