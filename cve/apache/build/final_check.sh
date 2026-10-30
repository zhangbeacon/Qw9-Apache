#!/bin/bash
E=/mnt/e/强网拟态/cve/apache/evidence/CVE-2021-44790
echo "== 44790 files =="; ls -la "$E"
echo "== verdict =="; cat "$E/verdict.txt"
echo "== crash lines =="; grep -n -E 'AH00051|Memory allocation failed|dispatch' "$E/error_log.txt" | tail -12
echo
echo "== 41773 files =="; ls /mnt/e/强网拟态/cve/apache/evidence/CVE-2021-41773
echo "== 41773 verdict =="; cat /mnt/e/强网拟态/cve/apache/evidence/CVE-2021-41773/verdict.txt
echo "== 44224 verdict =="; cat /mnt/e/强网拟态/cve/apache/evidence/CVE-2021-44224/verdict.txt
echo "== left processes =="; ps -ef | grep -E '/opt/httpd|uds_backend' | grep -v grep || echo none
echo "== ports via python =="
python3 - <<'PY'
for p in ('/proc/net/tcp','/proc/net/tcp6'):
    try:
        for line in open(p).read().splitlines()[1:]:
            f=line.split()
            if f[3]!='0A': continue
            print(p, int(f[1].split(':')[1],16))
    except FileNotFoundError: pass
PY
