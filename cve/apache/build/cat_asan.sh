#!/bin/bash
for f in /opt/httpd-asan/logs/asan.*; do
  echo "===== $f ($(stat -c%s "$f") bytes)"
  head -50 "$f"
done
