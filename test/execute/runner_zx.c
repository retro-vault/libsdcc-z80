// gpl-2.0-or-later (see: LICENSE)
// copyright (c) 2025 tomaz stih

#include <stdint.h>

// ROM I/O
void zx_putc(char ch);
void zx_puts(const char* s);
void zx_crlf(void);

static void puts_ok(const char* name) {
    zx_puts("ok  ");
    zx_puts(name);
    zx_crlf();
}
static void puts_fail(const char* name) {
    zx_puts("FAIL ");
    zx_puts(name);
    zx_crlf();
}

static int closef(float a, float b, float eps) {
    float d = a - b;
    if (d < 0.0f) d = -d;
    return d <= eps;
}

static int test_add(void) {
    const char* name = "add 1.5 + 2.25 ~= 3.75";
    float r = 1.5f + 2.25f;
    if (closef(r, 3.75f, 0.01f)) { puts_ok(name); return 1; }
    puts_fail(name); return 0;
}

static int test_sub(void) {
    const char* name = "sub 5.0 - 2.5 ~= 2.5";
    float r = 5.0f - 2.5f;
    if (closef(r, 2.5f, 0.01f)) { puts_ok(name); return 1; }
    puts_fail(name); return 0;
}

static int test_mul(void) {
    const char* name = "mul 3.5 * 2.0 ~= 7.0";
    float r = 3.5f * 2.0f;
    if (closef(r, 7.0f, 0.02f)) { puts_ok(name); return 1; }
    puts_fail(name); return 0;
}

static int test_div(void) {
    const char* name = "div 7.5 / 2.5 ~= 3.0";
    float r = 7.5f / 2.5f;
    if (closef(r, 3.0f, 0.02f)) { puts_ok(name); return 1; }
    puts_fail(name); return 0;
}

static int test_cmp(void) {
    const char* n1 = "cmp 1.0 < 2.0";
    const char* n2 = "cmp 2.0 == 2.0";
    int ok = 1;
    if ( (1.0f < 2.0f) ) puts_ok(n1); else { puts_fail(n1); ok = 0; }
    if ( (2.0f == 2.0f) ) puts_ok(n2); else { puts_fail(n2); ok = 0; }
    return ok;
}

static int test_conv(void) {
    const char* name = "conv uint<->float 12345";
    unsigned int u = 12345u;
    float f = (float)u;
    unsigned int u2 = (unsigned int)f;
    if (u2 == u) { puts_ok(name); return 1; }
    puts_fail(name); return 0;
}

int main(void) {
    int passed = 0, total = 0;

    zx_puts("ZX float smoke tests");
    zx_crlf();

    total++; passed += test_add();
    total++; passed += test_sub();
    total++; passed += test_mul();
    total++; passed += test_div();
    total++; passed += test_cmp();
    total++; passed += test_conv();

    zx_crlf();
    zx_puts("Summary: ");
    char buf[8];
    buf[0] = '0' + (char)passed; buf[1] = '/'; buf[2] = '0' + (char)total; buf[3] = 0;
    zx_puts(buf);
    zx_crlf();

    return 0;
}
