#!/bin/bash
# 四评审共用：串行复跑三款软件的一键验证（不重建二进制），全量输出落 _audit/<tag>-run.log
# 用法：bash audit_agent.sh <tag>
set -u
TAG=${1:?usage: audit_agent.sh <tag>}
ROOT=/mnt/e/强网拟态/cve
mkdir -p "$ROOT/_audit"
LOG="$ROOT/_audit/${TAG}-run.log"

# 全局锁：四个评审串行执行，避免抢 8081/8082/5353/8053 端口与 pkill 互杀
exec 9>/tmp/cve-audit.lock
if ! flock -w 3600 9; then
  echo "LOCK TIMEOUT after 3600s" >&2
  exit 3
fi

{
  echo "########## audit tag=$TAG start $(date -Is)"
  echo "===== nginx ====="
  bash "$ROOT/nginx/build/review-regression.sh" 2>&1 | tail -45
  echo "===== dnsmasq ====="
  bash "$ROOT/dnsmasq/build/run_all.sh" 2>&1 | tail -40
  echo "===== apache ====="
  bash "$ROOT/apache/build/run_all_verify.sh" 2>&1 | tail -40
  echo "########## audit tag=$TAG end $(date -Is)"
} > "$LOG" 2>&1

echo "log: $LOG"
grep -E 'RESULT|exit code:|HIT|miss|NEGATIVE|PASS|verify.sh exit' "$LOG" | tail -40
