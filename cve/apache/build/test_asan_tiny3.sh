#!/bin/bash
set -u
cat > /tmp/asan_neg3.c <<'EOF'
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
int main(void) {
    char *p = malloc(1);
    size_t n = (size_t)-1;
    p[0] = 'a';
    fprintf(stderr, "before memcpy n=%zu\n", n);
    memcpy(p, "x", n);
    fprintf(stderr, "after memcpy p[0]=%d\n", (int)p[0]);
    return 0;
}
EOF
gcc -g -O0 -fsanitize=address -fno-omit-frame-pointer -o /tmp/asan_neg3 /tmp/asan_neg3.c
echo "compile rc=$?"
echo "== disasm has memcpy? =="; objdump -d /tmp/asan_neg3 | grep -E 'call.*memcpy|__asan_memcpy|<memcpy' | head
ASAN_OPTIONS=detect_leaks=0:abort_on_error=1:handle_segv=1 /tmp/asan_neg3 > /tmp/asan_neg3.out 2>&1
echo "run exit=$?"
head -50 /tmp/asan_neg3.out
