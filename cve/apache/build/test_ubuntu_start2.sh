#!/bin/bash
echo '=== debug stderr, 4s ==='
timeout 4 /usr/sbin/apache2 -f /tmp/apacheA/neg/42013.conf -DFOREGROUND -e debug 2>&1
echo "rc=$?"
echo '=== single process -X, 3s ==='
timeout 3 /usr/sbin/apache2 -f /tmp/apacheA/neg/42013.conf -X -e debug 2>&1
echo "rc=$?"
