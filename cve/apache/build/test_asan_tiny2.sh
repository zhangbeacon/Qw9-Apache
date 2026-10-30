#!/bin/bash
set -u
cat > /tmp/asan_neg2.c <<'EOF'
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
int main(void) {
    char *p = malloc(1);
    volatile size_t n = (size_t)-1;
    p[0] = 'a';
    fprintf(stderr, "before memcpy n=%zu\n", (size_t)n);
    memcpy(p, "x", n);
    fprintf(stderr, "after memcpy\n");
    return 0;
}
EOF
gcc -g -O1 -fsanitize=address -fno-omit-frame-pointer -o /tmp/asan_neg2 /tmp/asan_neg2.c
echo "compile rc=$?"
ASAN_OPTIONS=detect_leaks=0:abort_on_error=1:handle_segv=1 /tmp/asan_neg2 > /tmp/asan_neg2.out 2>&1
echo "run exit=$?"
head -40 /tmp/asan_neg2.out
echo "== disasm memcpy in tiny =="
objdump -d /tmp/asan_neg2 | grep -B3 -A1 'memcpy' | head -20
echo "== nm =="
nm -D /tmp/asan_neg2 | grep -i memcpy || true
nm -D /lib/x86_64-linux-gnu/libasan.so.6 | grep ' memcpy' || true
