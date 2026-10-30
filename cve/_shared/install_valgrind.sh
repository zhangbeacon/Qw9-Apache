#!/bin/bash
set -u
bash /mnt/e/强网拟态/cve/_shared/netfix.sh >/dev/null 2>&1
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 3; done
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends valgrind >/tmp/valgrind-install.log 2>&1
echo "rc=$?"
which valgrind && valgrind --version
