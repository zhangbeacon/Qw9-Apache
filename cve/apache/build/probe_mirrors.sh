#!/bin/bash
for u in \
  https://mirrors.aliyun.com/apache/httpd/httpd-2.4.52.tar.gz \
  https://mirrors.tuna.tsinghua.edu.cn/apache/httpd/httpd-2.4.52.tar.gz \
  https://mirrors.ustc.edu.cn/apache/httpd/httpd-2.4.52.tar.gz \
  https://codeload.github.com/apache/httpd/tar.gz/refs/tags/2.4.52 \
  https://github.com/apache/httpd/archive/refs/tags/2.4.52.tar.gz
do
  echo "== $u"
  curl -sIL --max-time 8 "$u" | head -4
  echo
done
