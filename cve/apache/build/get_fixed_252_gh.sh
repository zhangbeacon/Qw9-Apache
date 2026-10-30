#!/bin/bash
set -u
DL=/mnt/e/强网拟态/cve/_downloads
WORK=/root/work/apache
OUT=/mnt/e/强网拟态/cve/apache/build
echo "== tools =="
for t in autoconf automake libtoolize m4 gcc make; do command -v $t || echo "MISS $t"; done
echo "== download github tag =="
curl -fL --retry 2 -o "$DL/httpd-2.4.52-github.tar.gz" \
  https://codeload.github.com/apache/httpd/tar.gz/refs/tags/2.4.52
ls -l "$DL/httpd-2.4.52-github.tar.gz"
sha256sum "$DL/httpd-2.4.52-github.tar.gz"
rm -rf "$WORK/httpd-2.4.52-gh"
mkdir -p "$WORK/httpd-2.4.52-gh"
tar xzf "$DL/httpd-2.4.52-github.tar.gz" -C "$WORK/httpd-2.4.52-gh" --strip-components=1
cd "$WORK/httpd-2.4.52-gh"
ls configure buildconf 2>/dev/null
grep -E 'AP_SERVER_(MAJOR|MINOR|PATCHLEVEL)_NUMBER' include/ap_release.h | head -3
echo "== buildconf =="
./buildconf > "$OUT/buildconf-252.log" 2>&1
echo "buildconf rc=$?"
tail -8 "$OUT/buildconf-252.log"
ls -l configure 2>/dev/null
