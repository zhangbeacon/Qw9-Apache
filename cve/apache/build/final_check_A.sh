#!/bin/bash
# 子智能体 A：最终自检
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
echo "== bash -n =="
for f in \
  "$ROOT/poc/CVE-2023-25690/verify.sh" \
  "$ROOT/poc/CVE-2022-22720/verify.sh" \
  "$ROOT/poc/CVE-2021-42013/verify.sh" \
  "$ROOT/poc/CVE-2021-42013/verify_2450_matrix.sh" \
  "$ROOT/poc/fixed_2.4.52/verify_negative_A.sh" \
  "$ROOT/build/run_all_A.sh"; do
  if bash -n "$f"; then echo "OK  $f"; else echo "SYNTAX FAIL $f"; fi
done
echo
echo "== python compile =="
python3 -m py_compile "$ROOT/poc/CVE-2023-25690/backend.py" "$ROOT/poc/CVE-2023-25690/probe.py" \
  "$ROOT/poc/CVE-2022-22720/probe.py" && echo "PY OK"
echo
echo "== CRLF check =="
file "$ROOT/poc/CVE-2023-25690/verify.sh" "$ROOT/poc/CVE-2022-22720/verify.sh" \
     "$ROOT/poc/CVE-2021-42013/verify.sh" "$ROOT/conf/CVE-2022-22720.conf" | sed 's#/mnt/e/强网拟态/cve/apache/##'
echo
echo "== port 8090/8091 =="
python3 - <<'PY'
import socket
for p in (8090, 8091):
    s = socket.socket(); s.settimeout(0.3)
    print(p, "free" if s.connect_ex(("127.0.0.1", p)) else "BUSY")
    s.close()
PY
echo
echo "== our processes (should be none) =="
ps -ef | grep -E 'CVE-2021-42013|CVE-2022-22720|CVE-2023-25690|apacheA/|httpd-2450' | grep -v grep || true
echo
echo "== evidence files =="
for d in CVE-2023-25690 CVE-2022-22720 CVE-2021-42013 fixed_2.4.52_A; do
  echo "--- $d ---"
  ls -1 "$ROOT/evidence/$d" 2>/dev/null
  echo "[verdict]"; cat "$ROOT/evidence/$d/verdict.txt" 2>/dev/null
done
echo
echo "== reports =="
ls -l "$ROOT/report/CVE-2023-25690.md" "$ROOT/report/CVE-2022-22720.md" "$ROOT/report/CVE-2021-42013.md"
echo
echo "== report placeholder check =="
grep -n 'TODO\|待补\|placeholder\|XXX' "$ROOT/report/CVE-2023-25690.md" "$ROOT/report/CVE-2022-22720.md" "$ROOT/report/CVE-2021-42013.md" || echo "no placeholders"
