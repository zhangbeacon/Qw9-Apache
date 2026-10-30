#!/bin/bash
# 子智能体 A：顺序跑三个正向 verify + 修复版负向对照，汇总退出码
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
LOG=/tmp/apacheA/run_all
mkdir -p "$LOG"
RC_SM=99; RC_22720=99; RC_42013=99; RC_NEG=99

run() { # $1 label, $2 verify path, $3 log name
  echo "################ $1 ################"
  bash "$2" > "$LOG/$3.log" 2>&1
  local rc=$?
  echo "$1 EXIT=$rc"
  tail -6 "$LOG/$3.log"
  echo
  return $rc
}

run "CVE-2023-25690" "$ROOT/poc/CVE-2023-25690/verify.sh" 25690; RC_SM=$?
run "CVE-2022-22720" "$ROOT/poc/CVE-2022-22720/verify.sh" 22720; RC_22720=$?
run "CVE-2021-42013" "$ROOT/poc/CVE-2021-42013/verify.sh" 42013; RC_42013=$?
run "fixed-2.4.52-negative" "$ROOT/poc/fixed_2.4.52/verify_negative_A.sh" negative; RC_NEG=$?

echo "================ SUMMARY ================"
echo "CVE-2023-25690 verify exit = $RC_SM"
echo "CVE-2022-22720 verify exit = $RC_22720"
echo "CVE-2021-42013 verify exit = $RC_42013"
echo "negative 2.4.52 exit      = $RC_NEG"
if [ "$RC_SM" = 0 ] && [ "$RC_22720" = 0 ] && [ "$RC_42013" = 0 ] && [ "$RC_NEG" = 0 ]; then
  echo "ALL PASS"
  exit 0
else
  echo "SOME FAILED"
  exit 1
fi
