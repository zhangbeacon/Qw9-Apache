#!/bin/bash
echo "== tiny ASAN memcpy negative-size test =="
cat > /tmp/asan_neg.c <<'EOF'
#include <string.h>
#include <stdlib.h>
int main(void) {
    char *p = malloc(1);
    p[0] = 0;
    memcpy(p, "x", (size_t)-1);
    return 0;
}
EOF
gcc -g -O1 -fsanitize=address -fno-omit-frame-pointer -o /tmp/asan_neg /tmp/asan_neg.c
ASAN_OPTIONS=detect_leaks=0:abort_on_error=1:handle_segv=1 /tmp/asan_neg > /tmp/asan_neg.out 2>&1
echo "exit=$?"
head -40 /tmp/asan_neg.out
echo "== ASAN mod_lua disasm around memcpy =="
objdump -d --disassemble=req_parsebody /opt/httpd-asan/modules/mod_lua.so 2>/dev/null | grep -n -B4 -A2 'memcpy' | head -40
