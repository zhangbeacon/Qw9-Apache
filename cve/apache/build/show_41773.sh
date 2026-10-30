#!/bin/bash
E=/mnt/e/强网拟态/cve/apache/evidence/CVE-2021-41773
ls -la "$E"
echo "--- passwd head ---"; head -3 "$E/file_read_passwd.txt"
echo "--- headers ---"; head -8 "$E/file_read_passwd_headers.txt"
echo "--- secret ---"; cat "$E/file_read_secret.txt"
echo "--- verdict ---"; cat "$E/verdict.txt"
