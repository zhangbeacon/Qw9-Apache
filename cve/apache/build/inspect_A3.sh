#!/bin/bash
SRC=/root/work/miner/src/httpd-2.4.49
echo "=== http_filters.c 340-470 ==="
sed -n '340,470p' "$SRC/modules/http/http_filters.c"
echo
echo "=== http_filters.c 470-650 ==="
sed -n '470,650p' "$SRC/modules/http/http_filters.c"
echo
echo "=== bail_out_on_error ==="
grep -n "bail_out_on_error" -A25 "$SRC/modules/http/http_filters.c" | head -45
echo
echo "=== mod_rewrite apply_rewrite_rule 3300-3420 ==="
sed -n '3300,3420p' "$SRC/modules/mappers/mod_rewrite.c"
echo
echo "=== mod_rewrite hook_uri2file 4600-4780 ==="
sed -n '4600,4780p' "$SRC/modules/mappers/mod_rewrite.c"
