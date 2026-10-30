#!/bin/bash
rm -f /tmp/apacheA/neg/trace.txt
timeout 3 strace -f -o /tmp/apacheA/neg/trace.txt /usr/sbin/apache2 -f /tmp/apacheA/neg/42013_rt.conf -DFOREGROUND
echo "rc=$?"
echo '=== last 60 syscalls ==='
tail -80 /tmp/apacheA/neg/trace.txt
