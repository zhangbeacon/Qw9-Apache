#!/bin/bash
R=/mnt/e/强网拟态/cve/apache
echo "== evidence dirs =="
for d in "$R"/evidence/CVE-*; do echo "--- $d"; ls "$d" | sort; done
echo "== fixed build =="; cat "$R/evidence/fixed_2.4.52_build.txt"
echo "== 44224 verdict =="; cat "$R/evidence/CVE-2021-44224/verdict.txt"
echo "== 44224 UDS log lines =="; grep -a 'UDS as' "$R/evidence/CVE-2021-44224/error_log.txt" | tail -4
echo "== 44790 verdict =="; cat "$R/evidence/CVE-2021-44790/verdict.txt"
echo "== 44790 crash lines =="; grep -a -E 'AH00051|Memory allocation' "$R/evidence/CVE-2021-44790/error_log.txt" | tail -4
echo "== 44790 logmemcpy =="; grep -a 'logmemcpy' "$R/evidence/CVE-2021-44790/logmemcpy_huge_call.txt"
echo "== fixed negative verdicts =="
for f in "$R"/evidence/CVE-*/fixed_2.4.52_negative.txt; do echo "--- $f"; grep -a -E 'fixed|HTTP/1.1|parsebody survived|SECRET_FROM' "$f" | head -6; done
echo "== leftover processes =="; ps -ef | grep -E '/opt/httpd|httpd252-root|/usr/sbin/apache2|uds_backend' | grep -v grep || echo none
