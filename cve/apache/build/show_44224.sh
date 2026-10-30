#!/bin/bash
E=/mnt/e/强网拟态/cve/apache/evidence/CVE-2021-44224
echo "--- response ---"; cat "$E/poc_response.txt"
echo; echo "--- backend log ---"; cat "$E/uds_backend.log"
echo; echo "--- probe ---"; cat "$E/probe_no_hostname.txt"
echo "--- verdict ---"; cat "$E/verdict.txt"
echo "--- error tail ---"; tail -20 "$E/error_log.txt"
echo "--- access tail ---"; tail -10 "$E/access_log.txt"
echo "--- process after ---"; cat "$E/process_after.txt"
