#!/bin/bash
# 诊断 CVE-2022-23943：采样 mod_sed 处理超长行时的 worker RSS 峰值
set -u
ROOT="/mnt/e/强网拟态/cve/apache"
RUN=/tmp/cve-2022-23943
DOC=/opt/httpd/htdocs
PREFIX=/opt/httpd
PORT=8095
BASE="http://127.0.0.1:$PORT"
mkdir -p "$RUN" "$DOC"
sed -e "s#Listen 8095#Listen $PORT#" -e "s#/tmp/cve-2022-23943#${RUN}#g" \
    "$ROOT/conf/CVE-2022-23943.conf" > "$RUN/sed.conf"
[ -f "$DOC/index.html" ] || echo '<html>lab</html>' > "$DOC/index.html"
echo "--- /proc/self/status mem fields ---"
grep -E 'VmHWM|VmRSS|VmPeak' /proc/self/status || echo "(none)"
echo "--- /proc/meminfo mem fields ---"
grep -E 'MemTotal|MemFree|MemAvailable|SwapFree' /proc/meminfo || echo "(none)"

cd "$PREFIX"
"$PREFIX/bin/httpd" -f "$RUN/sed.conf" -DFOREGROUND > "$RUN/console.log" 2>&1 &
HPID=$!
for i in $(seq 1 80); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "$BASE/" 2>/dev/null || true)
  if [ -n "$code" ] && [ "$code" != "000" ]; then break; fi
  sleep 0.25
done

sample_peak() { # sample_peak <pid> <outfile> <duration-seconds>
  local pid=$1 out=$2 dur=$3
  local max=0 rss
  local end=$(( $(date +%s%N) + dur*1000000000 ))
  while [ "$(date +%s%N)" -lt "$end" ]; do
    for w in $(pgrep -P "$pid"); do
      rss=$(awk '{print $2*4}' /proc/$w/statm 2>/dev/null || echo 0)  # pages*4kB
      [ "${rss:-0}" -gt "$max" ] && max=$rss
    done
    sleep 0.02
  done
  echo "$max" > "$out"
}

for MB in 8 32 128 256; do
  SIZE=$((MB*1024*1024))
  truncate -s "$SIZE" "$DOC/bigline"
  echo "===== bigline ${MB}MB ====="
  sample_peak "$HPID" "$RUN/peak.txt" 60 &
  SPID=$!
  OUT=$(curl -sS --max-time 120 -o /dev/null -w 'http=%{http_code} size=%{size_download} time=%{time_total}' "$BASE/bigline" 2>&1)
  echo "$OUT"
  wait $SPID 2>/dev/null || true
  kill $SPID 2>/dev/null || true
  echo "  peak_worker_rss_kB=$(cat "$RUN/peak.txt" 2>/dev/null)"
  sleep 0.5
  for p in $(pgrep -P "$HPID"); do
    echo "  worker $p now_rss=$(awk '{print $2*4}' /proc/$p/statm 2>/dev/null) kB"
  done
done
kill "$HPID" 2>/dev/null; sleep 1; kill -9 "$HPID" 2>/dev/null
rm -f "$DOC/bigline" "$RUN/httpd.pid"
