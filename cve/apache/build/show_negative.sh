#!/bin/bash
E=/mnt/e/强网拟态/cve/apache/evidence
echo "===== fixed build ====="; cat "$E/fixed_2.4.52_build.txt"
echo; echo "===== 41773 negative ====="; cat "$E/CVE-2021-41773/fixed_2.4.52_negative.txt"
echo; echo "===== 44224 negative ====="; cat "$E/CVE-2021-44224/fixed_2.4.52_negative.txt"
echo; echo "===== 44790 negative ====="; cat "$E/CVE-2021-44790/fixed_2.4.52_negative.txt"
