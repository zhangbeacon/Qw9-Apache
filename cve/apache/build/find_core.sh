#!/bin/bash
echo "== core_pattern =="; cat /proc/sys/kernel/core_pattern; ulimit -c
echo "== core files =="
ls -la /opt/httpd-asan/core* /opt/httpd/core* /tmp/core* /root/core* 2>/dev/null || echo none
echo "== find recent cores =="
find /opt/httpd-asan /opt/httpd /tmp /root -maxdepth 2 -name 'core*' -newermt '-30 minutes' -ls 2>/dev/null | head -20
echo "== apport =="
ls -la /var/lib/apport/coredump 2>/dev/null | tail -5
