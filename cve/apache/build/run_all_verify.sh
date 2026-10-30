#!/bin/bash
ROOT=/mnt/e/强网拟态/cve/apache
echo "########## 41773 ##########"
bash "$ROOT/poc/CVE-2021-41773/verify.sh"; echo "exit=$?"
echo "########## 44224 ##########"
bash "$ROOT/poc/CVE-2021-44224/verify.sh"; echo "exit=$?"
echo "########## 44790 ##########"
bash "$ROOT/poc/CVE-2021-44790/verify.sh"; echo "exit=$?"
echo "########## fixed 2.4.52 negative ##########"
bash "$ROOT/poc/fixed_2.4.52/verify_negative_ubuntu.sh"; echo "exit=$?"
