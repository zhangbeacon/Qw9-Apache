#!/bin/bash
for cve in 42013 25690 22720; do
  mkdir -p /tmp/apacheA/neg/$cve
  cp /tmp/apacheA/neg/$cve.conf /tmp/apacheA/neg/${cve}_rt.conf 2>/dev/null || cp /tmp/apacheA/neg/42013.conf /tmp/apacheA/neg/${cve}_rt.conf
  sed -i "1i DefaultRuntimeDir /tmp/apacheA/neg/$cve" /tmp/apacheA/neg/${cve}_rt.conf
done
echo '=== config test 42013 ==='
/usr/sbin/apache2 -t -f /tmp/apacheA/neg/42013_rt.conf
echo "rc=$?"
echo '=== start 42013 3s ==='
timeout 3 /usr/sbin/apache2 -f /tmp/apacheA/neg/42013_rt.conf -DFOREGROUND -e debug 2>&1 | tail -15
echo "rc=${PIPESTATUS[0]}"
