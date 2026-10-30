#!/bin/bash
SRC=/root/work/miner/src/httpd-2.4.49
echo "=== mod_reqtimeout.c 60-360 ==="
sed -n '60,360p' "$SRC/modules/filters/mod_reqtimeout.c"
echo
echo "=== core input filter: error handling ==="
sed -n '95,200p' "$SRC/server/core_filters.c"
echo
echo "=== core input filter around 200-320 ==="
sed -n '200,320p' "$SRC/server/core_filters.c"
