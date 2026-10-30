#!/bin/bash
PREFIX=/opt/httpd-asan
echo "== ldd httpd =="; ldd "$PREFIX/bin/httpd" | head -10
echo "== ldd mod_lua =="; ldd "$PREFIX/modules/mod_lua.so" | grep -E 'asan|lua|c' | head
echo "== libasan path =="; gcc -print-file-name=libasan.so
echo "== core test =="
cd /tmp; rm -f core*; ulimit -c unlimited; bash -c 'kill -SEGV $$' 2>/dev/null; sleep 0.5; ls -l /tmp/core* 2>/dev/null || echo "no core in /tmp"
