#!/bin/bash
# 最终交付自检：证据文件是否存在、端口/进程是否干净、脚本可执行位
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
E="$ROOT/evidence"
fail=0
check() { [ -e "$1" ] && echo "OK   $1" || { echo "MISS $1"; fail=1; }; }
for f in \
  "$E/CVE-2024-38474/00_version_build.txt" \
  "$E/CVE-2024-38474/requests.txt" \
  "$E/CVE-2024-38474/body_baseline_profile.txt" \
  "$E/CVE-2024-38474/body_control_secret_plain.txt" \
  "$E/CVE-2024-38474/body_attack_secret_upper.txt" \
  "$E/CVE-2024-38474/body_attack_secret_lower.txt" \
  "$E/CVE-2024-38474/body_attack_secret_mid.txt" \
  "$E/CVE-2024-38474/body_attack_script_source.txt" \
  "$E/CVE-2024-38474/body_attack_mislead_handler.txt" \
  "$E/CVE-2024-38474/body_attack_double_encoded.txt" \
  "$E/CVE-2024-38474/rewrite_split_lines.txt" \
  "$E/CVE-2024-38474/error_log.txt" \
  "$E/CVE-2024-38474/verdict.txt" \
  "$E/CVE-2024-38474/conf_check.txt" \
  "$E/CVE-2024-38474/fixed_2.4.52_negative.txt" \
  "$E/CVE-2024-38474/fixed_2.4.52_error_log.txt" \
  "$E/CVE-2024-38474/fixed_2.4.52_changelog.txt" \
  "$E/CVE-2022-22719/00_version_build.txt" \
  "$E/CVE-2022-22719/lua_entry.txt" \
  "$E/CVE-2022-22719/requests.txt" \
  "$E/CVE-2022-22719/body_pos_multipart_get_nobody.txt" \
  "$E/CVE-2022-22719/body_pos_multipart_post_cl0.txt" \
  "$E/CVE-2022-22719/valgrind.log" \
  "$E/CVE-2022-22719/uninit_report.txt" \
  "$E/CVE-2022-22719/uninit_origin.txt" \
  "$E/CVE-2022-22719/valgrind_summary.txt" \
  "$E/CVE-2022-22719/verdict.txt" \
  "$E/CVE-2022-22719/fixed_2.4.52_negative.txt" \
  "$E/CVE-2022-22719/fixed_2.4.52_disasm.txt" \
  "$E/CVE-2022-22719/fixed_2.4.52_valgrind.log" \
  "$E/CVE-2022-23943/00_version_build.txt" \
  "$E/CVE-2022-23943/static_types.txt" \
  "$E/CVE-2022-23943/small_test.txt" \
  "$E/CVE-2022-23943/rss_samples.txt" \
  "$E/CVE-2022-23943/resource_assessment.txt" \
  "$E/CVE-2022-23943/meminfo.txt" \
  "$E/CVE-2022-23943/conf_check.txt" \
  "$E/CVE-2022-23943/access_log.txt" \
  "$E/CVE-2022-23943/error_log.txt" \
  "$E/CVE-2022-23943/verdict.txt" \
  "$ROOT/conf/CVE-2024-38474.conf" \
  "$ROOT/conf/CVE-2022-22719.conf" \
  "$ROOT/conf/CVE-2022-23943.conf" \
  "$ROOT/poc/CVE-2024-38474/verify.sh" \
  "$ROOT/poc/CVE-2022-22719/verify.sh" \
  "$ROOT/poc/CVE-2022-23943/verify.sh" \
  "$ROOT/report/CVE-2024-38474.md" \
  "$ROOT/report/CVE-2022-22719.md" \
  "$ROOT/report/CVE-2022-23943.md" \
  "$ROOT/poc/fixed_2.4.52/verify_negative_38474_22719.sh" \
  ; do check "$f"; done

echo "=== executable bits ==="
ls -l "$ROOT"/poc/CVE-2024-38474/verify.sh "$ROOT"/poc/CVE-2022-22719/verify.sh \
      "$ROOT"/poc/CVE-2022-23943/verify.sh "$ROOT"/poc/fixed_2.4.52/verify_negative_38474_22719.sh
echo "=== ports ==="
ss -ltn 2>/dev/null | grep -E ':809[56]|:810[3-5]' || echo PORTS_FREE
echo "=== leftover processes ==="
ps -ef | grep -E '/opt/httpd(-asan)?/bin/httpd|valgrind.*httpd|httpd252-cve' | grep -v grep || echo NO_LEFTOVERS
echo "=== /opt/httpd/conf untouched? ==="
ls -l /opt/httpd/conf/httpd.conf
echo "=== report/evidence sizes ==="
du -sh "$E"/CVE-2024-38474 "$E"/CVE-2022-22719 "$E"/CVE-2022-23943
echo "SELFCHECK_FAIL=$fail"
exit "$fail"
