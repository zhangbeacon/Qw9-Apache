#!/bin/bash
cp /tmp/apacheA/neg/42013.conf /tmp/apacheA/neg/42013_user.conf
printf '\nUser www-data\nGroup www-data\n' >> /tmp/apacheA/neg/42013_user.conf
echo '=== config test ==='
/usr/sbin/apache2 -t -f /tmp/apacheA/neg/42013_user.conf
echo "rc=$?"
echo '=== start 4s ==='
timeout 4 /usr/sbin/apache2 -f /tmp/apacheA/neg/42013_user.conf -DFOREGROUND -e debug 2>&1
echo "rc=$?"
echo '=== port ==='
python3 - <<'PY'
import socket
s = socket.socket(); s.settimeout(0.3)
print(s.connect_ex(("127.0.0.1", 8090)))
s.close()
PY
