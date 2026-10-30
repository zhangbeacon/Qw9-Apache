#!/bin/bash
E=/mnt/e/强网拟态/cve/apache/evidence
for c in CVE-2023-25690 CVE-2022-22720 CVE-2021-42013 fixed_2.4.52_A; do
  echo "########## $c ##########"
  ls -la "$E/$c" 2>/dev/null
  echo "--- verdict ---"
  cat "$E/$c/verdict.txt" 2>/dev/null
  echo
done
echo "########## 25690 error_log key ##########"
grep -E 'init rewrite engine|applying pattern|rewrite .*->|split uri|go-ahead' "$E/CVE-2023-25690/error_log.txt" 2>/dev/null | head -8
echo
echo "########## 22720 access ##########"
cat "$E/CVE-2022-22720/access_log.txt" 2>/dev/null
echo
echo "########## 42013 access ##########"
cat "$E/CVE-2021-42013/access_log.txt" 2>/dev/null
echo
echo "########## version ##########"
head -8 "$E/CVE-2023-25690/00_version_build.txt"
