#!/bin/bash
set -u
ROOT=/mnt/e/强网拟态/cve/apache
echo "== ports =="
python3 - <<'PY'
import socket
for p in (8090, 8091):
    s = socket.socket(); s.settimeout(0.3)
    print(p, "free" if s.connect_ex(("127.0.0.1", p)) else "BUSY")
    s.close()
PY
echo
echo "== our processes =="
ps -ef | grep -E 'CVE-2021-42013|CVE-2022-22720|CVE-2023-25690|apacheA/|httpd-2450' | grep -v grep || echo none
echo
echo "== 25690 verdict =="; cat "$ROOT/evidence/CVE-2023-25690/verdict.txt"
echo
echo "== 22720 verdict =="; cat "$ROOT/evidence/CVE-2022-22720/verdict.txt"
echo
echo "== 42013 verdict =="; cat "$ROOT/evidence/CVE-2021-42013/verdict.txt"
echo
echo "== 42013 2450 verdict =="; cat "$ROOT/evidence/CVE-2021-42013/2450_verdict.txt"
echo
echo "== negative verdict =="; cat "$ROOT/evidence/fixed_2.4.52_A/verdict.txt"
echo
echo "== negative key lines =="
grep -E 'AH10410|HTTP/1.1 408|HTTP/1.1 400|resp2_has_200' "$ROOT/evidence/fixed_2.4.52_A/"*.txt | head -12
echo
echo "== 22720 trailer files =="
ls -1 "$ROOT/evidence/CVE-2022-22720" | grep -E 'chunktrailer|chunkbad|clbad'
echo
echo "== report sizes =="
wc -l "$ROOT/report/CVE-2023-25690.md" "$ROOT/report/CVE-2022-22720.md" "$ROOT/report/CVE-2021-42013.md"
echo
echo "== no /opt/httpd/conf writes by A (list mtimes) =="
ls -la /opt/httpd/conf | head
