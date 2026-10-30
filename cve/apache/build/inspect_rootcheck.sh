#!/bin/bash
cd /root/work/apache/httpd-2.4.49
grep -rn "above the root path" server/ modules/ | head
sed -n '/The given path was above the root path/,+20p' server/request.c
echo "===== AH00127 context ====="
grep -n "AH00127" server/request.c
sed -n '450,520p' server/request.c
