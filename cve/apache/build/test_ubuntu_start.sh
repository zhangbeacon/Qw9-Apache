#!/bin/bash
echo '=== config test ==='
/usr/sbin/apache2 -t -f /tmp/apacheA/neg/42013.conf
echo "rc=$?"
echo '=== foreground 3s ==='
timeout 3 /usr/sbin/apache2 -f /tmp/apacheA/neg/42013.conf -DFOREGROUND
echo "rc=$?"
echo '=== pidfile ==='
cat /tmp/apacheA/neg/42013/httpd.pid 2>/dev/null
echo '=== port 8090 connect_ex (0=open) ==='
python3 - <<'PY'
import socket
s = socket.socket(); s.settimeout(0.3)
print(s.connect_ex(("127.0.0.1", 8090)))
s.close()
PY
echo '=== ps apache2 ==='
ps -ef | grep apache2 | grep -v grep || true
