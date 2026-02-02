// gpl-2.0-or-later (see: LICENSE)
// (c) 2025 tomaz stih

#include <stdint.h>
#include <zx/spectrum.h>

/* ---------- tiny print helpers ---------- */

static char hex_digit(uint8_t n){ n&=0x0F; return (n<10)?('0'+n):('A'+(n-10)); }

static void put_hex16(uint16_t v){
    char b[5];
    b[0]=hex_digit((uint8_t)(v>>12));
    b[1]=hex_digit((uint8_t)(v>>8));
    b[2]=hex_digit((uint8_t)(v>>4));
    b[3]=hex_digit((uint8_t)v);
    b[4]=0;
    cputs(b);
}

static void put_hex32(uint32_t v) {
    put_hex16((uint16_t)(v >> 16));   // high word first
    put_hex16((uint16_t)(v & 0xFFFF)); // low word
}


/* status lines */
static void ok  (const char *name){ cputs("ok  ");  cputs(name); cputs("\n"); }
static void fail(const char *name){ cputs("FAIL "); cputs(name); cputs("\n"); }

/* ---------- “make value non-constant” helpers (C89/SDCC-safe) ---------- */

static uint8_t  mk_u8 (uint8_t  x){ volatile uint8_t  t=x; return t; }
static  int8_t  mk_s8 ( int8_t  x){ volatile  int8_t  t=x; return t; }
static uint16_t mk_u16(uint16_t x){ volatile uint16_t t=x; return t; }
static  int16_t mk_s16( int16_t x){ volatile  int16_t t=x; return t; }
static uint32_t mk_u32(uint32_t x){ volatile uint32_t t=x; return t; }
/* SDCC “long” is 32-bit; keep both typedefs for clarity */
static  int32_t mk_s32( int32_t x){ volatile  int32_t t=x; return t; }

/* ---------- f32 bit-cast helpers (no printf, compare by bits) ---------- */

typedef union f32u_u {
    float    f;
    uint32_t u;
} f32u_t;

static float mk_f32(uint32_t bits) {
    volatile f32u_t t;
    t.u = mk_u32(bits);   /* volatile barrier on the integer payload */
    return t.f;           /* reinterpret bits as float */
}

static uint32_t f32_bits(float x) {
    volatile f32u_t t;
    t.f = x;              /* volatile barrier on the float payload */
    return mk_u32(t.u);   /* volatile barrier on the extracted bits */
}

/* ---------- debugging ---------- */
extern volatile uint8_t  fdebug_b1, fdebug_b2, fdebug_b3, fdebug_b4;
extern volatile uint16_t fdebug_w1, fdebug_w2, fdebug_w3, fdebug_w4;

static void dump_fdebug(void){
    cputs("dbg b: ");
    put_hex16((uint16_t)fdebug_b1); cputc(' ');
    put_hex16((uint16_t)fdebug_b2); cputc(' ');
    put_hex16((uint16_t)fdebug_b3); cputc(' ');
    put_hex16((uint16_t)fdebug_b4); cputs("\n");

    cputs("dbg w: ");
    put_hex16(fdebug_w1); cputc(' ');
    put_hex16(fdebug_w2); cputc(' ');
    put_hex16(fdebug_w3); cputc(' ');
    put_hex16(fdebug_w4); cputs("\n");
}


/* ---------- initial float tests for add and sub ---------- */

static int test_f32_add_basic(void) {
    const char *name = "f32 1.25 + (-2.5) == -1.25";
    float a = 1.25f; //mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    float b = -2.5f; // mk_f32(mk_u32(0xC0200000UL));  /* -2.5 */
    float r = a + b;                          /* ___fsadd */
    uint32_t got = mk_u32(f32_bits(r));
    if (got == mk_u32(0xBFA00000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_sub_basic(void) {
    const char *name = "f32 1.25 - (-2.5) == 3.75";
    float a = mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    float b = mk_f32(mk_u32(0xC0200000UL));  /* -2.5 */
    float r = a - b;                          /* ___fssub */
    if (mk_u32(f32_bits(r)) == mk_u32(0x40700000UL)) { ok(name); return 1; } /* 3.75 */
    fail(name); return 0;
}


/* ---------- float to int conversions ---------- */
static int test_fs2sint_trunc_pos(void) {
    const char *name = "(int)1.75f == 1 (truncate toward zero)";
    float f = mk_f32(mk_u32(0x3FE00000UL)); /* 1.75 */
    int got = (int)f;
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2sint_trunc_neg(void) {
    const char *name = "(int)-1.75f == -1 (truncate toward zero)";
    float f = mk_f32(mk_u32(0xBFE00000UL)); /* -1.75 */
    int got = (int)f;
    if (got == -1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2sint_pos_overflow(void) {
    const char *name = "(int)32768.0f clamps to 32767";
    float f = mk_f32(mk_u32(0x47000000UL)); /* 32768.0 */
    int got = (int)f;
    if (got == 32767) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2sint_neg_overflow(void) {
    const char *name = "(int)-40000.0f clamps to -32768";
    float f = mk_f32(mk_u32(0xC71C4000UL)); /* -40000.0 */
    int got = (int)f;
    if (got == -32768) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2sint_subunit(void) {
    const char *name = "(int)0.5f == 0";
    float f = mk_f32(mk_u32(0x3F000000UL)); /* 0.5 */
    int got = (int)f;
    if (got == 0) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2sint_one(void) {
    const char *name = "(int)1.0f == 1";
    float f = mk_f32(mk_u32(0x3F800000UL)); /* 1.0 */
    int got = (int)f;
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2schar_trunc_pos(void) {
    const char *name = "(signed char)1.75f == 1";
    float f = mk_f32(mk_u32(0x3FE00000UL)); /* 1.75 */
    signed char got = (signed char)f;
    if ((int)got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2schar_trunc_neg(void) {
    const char *name = "(signed char)-1.75f == -1";
    float f = mk_f32(mk_u32(0xBFE00000UL)); /* -1.75 */
    signed char got = (signed char)f;
    if ((int)got == -1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2schar_wrap_128(void) {
    const char *name = "(signed char)128.0f == -128 (low-byte truncation)";
    float f = mk_f32(mk_u32(0x43000000UL)); /* 128.0 */
    signed char got = (signed char)f;
    if ((int)got == -128) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_to_u16_trunc(void) {
    const char *name = "(unsigned int)1.75f == 1";
    float f = mk_f32(mk_u32(0x3FE00000UL)); /* 1.75 */
    unsigned int got = (unsigned int)f;
    if (got == 1u) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_to_u16_negative_zero(void) {
    const char *name = "(unsigned int)-1.75f == 0";
    float f = mk_f32(mk_u32(0xBFE00000UL)); /* -1.75 */
    unsigned int got = (unsigned int)f;
    if (got == 0u) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_to_u16_overflow_clamp(void) {
    const char *name = "(unsigned int)65536.0f clamps to 65535";
    float f = mk_f32(mk_u32(0x47800000UL)); /* 65536.0 */
    unsigned int got = (unsigned int)f;
    if (got == 65535u) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_to_u16_max_exact(void) {
    const char *name = "(unsigned int)65535.0f == 65535";
    float f = mk_f32(mk_u32(0x477FFF00UL)); /* 65535.0 */
    unsigned int got = (unsigned int)f;
    if (got == 65535u) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2uchar_trunc_pos(void) {
    const char *name = "(unsigned char)1.75f == 1";
    float f = mk_f32(mk_u32(0x3FE00000UL)); /* 1.75 */
    unsigned char got = (unsigned char)f;
    if ((unsigned int)got == 1u) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2uchar_wrap_256(void) {
    const char *name = "(unsigned char)256.0f == 0 (low-byte truncation)";
    float f = mk_f32(mk_u32(0x43800000UL)); /* 256.0 */
    unsigned char got = (unsigned char)f;
    if ((unsigned int)got == 0u) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2slong_trunc_pos(void) {
    const char *name = "(long)1.75f == 1";
    float f = mk_f32(mk_u32(0x3FE00000UL)); /* 1.75 */
    long got = (long)f;
    if ((uint32_t)got == mk_u32(0x00000001UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2slong_trunc_neg(void) {
    const char *name = "(long)-1.75f == -1";
    float f = mk_f32(mk_u32(0xBFE00000UL)); /* -1.75 */
    long got = (long)f;
    if ((uint32_t)got == mk_u32(0xFFFFFFFFUL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2slong_clamp_pos(void) {
    const char *name = "(long)2147483648.0f clamps to 0x7FFFFFFF";
    float f = mk_f32(mk_u32(0x4F000000UL)); /* 2^31 */
    long got = (long)f;
    if ((uint32_t)got == mk_u32(0x7FFFFFFFUL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2slong_clamp_neg(void) {
    const char *name = "(long)-2147483648.0f == 0x80000000";
    float f = mk_f32(mk_u32(0xCF000000UL)); /* -2^31 */
    long got = (long)f;
    if ((uint32_t)got == mk_u32(0x80000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2slong_word_order_sentinel(void) {
    const char *name = "(long)65536.0f == 65536 (checks word order)";
    float f = mk_f32(mk_u32(0x47800000UL)); /* 65536.0 */
    long got = (long)f;
    if ((uint32_t)got == mk_u32(0x00010000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2ulong_trunc_pos(void) {
    const char *name = "(unsigned long)1.75f == 1";
    float f = mk_f32(mk_u32(0x3FE00000UL)); /* 1.75 */
    unsigned long got = (unsigned long)f;
    if (mk_u32((uint32_t)got) == mk_u32(0x00000001UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2ulong_neg_zero(void) {
    const char *name = "(unsigned long)-1.75f == 0";
    float f = mk_f32(mk_u32(0xBFE00000UL)); /* -1.75 */
    unsigned long got = (unsigned long)f;
    if (mk_u32((uint32_t)got) == mk_u32(0x00000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2ulong_clamp_2p32(void) {
    const char *name = "(unsigned long)4294967296.0f clamps to 0xFFFFFFFF";
    float f = mk_f32(mk_u32(0x4F800000UL)); /* 2^32 */
    unsigned long got = (unsigned long)f;
    if (mk_u32((uint32_t)got) == mk_u32(0xFFFFFFFFUL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_fs2ulong_word_order_sentinel(void) {
    const char *name = "(unsigned long)65536.0f == 65536";
    float f = mk_f32(mk_u32(0x47800000UL)); /* 65536.0 */
    unsigned long got = (unsigned long)f;
    if (mk_u32((uint32_t)got) == mk_u32(0x00010000UL)) { ok(name); return 1; }
    fail(name); return 0;
}


/* ---------- main ---------- */

void main(void){
    cinit();
    cclear();

    int passed=0, total=0;

    cputs("ZX float helper suite\n");

    total++; passed += test_f32_add_basic();
    total++; passed += test_f32_sub_basic();
    total++; passed += test_fs2sint_trunc_pos();
    total++; passed += test_fs2sint_trunc_neg();
    total++; passed += test_fs2sint_pos_overflow();
    total++; passed += test_fs2sint_neg_overflow();
    total++; passed += test_fs2sint_subunit();
    total++; passed += test_fs2sint_one();
    total++; passed += test_fs2schar_trunc_pos();
    total++; passed += test_fs2schar_trunc_neg();
    total++; passed += test_fs2schar_wrap_128();
    total++; passed += test_f32_to_u16_trunc();
    total++; passed += test_f32_to_u16_negative_zero();
    total++; passed += test_f32_to_u16_overflow_clamp();
    total++; passed += test_f32_to_u16_max_exact();
    total++; passed += test_fs2uchar_trunc_pos();
    total++; passed += test_fs2uchar_wrap_256();
    total++; passed += test_fs2slong_trunc_pos();
    total++; passed += test_fs2slong_trunc_neg();
    total++; passed += test_fs2slong_clamp_pos();
    total++; passed += test_fs2slong_clamp_neg();
    total++; passed += test_fs2slong_word_order_sentinel();
    
    total++; passed += test_fs2ulong_trunc_pos();
    total++; passed += test_fs2ulong_neg_zero();
    total++; passed += test_fs2ulong_clamp_2p32();
    /* optional */
    total++; passed += test_fs2ulong_word_order_sentinel();


    dump_fdebug();

    cputs("Summary: ");
    put_hex16((uint16_t)passed);
    cputc('/');
    put_hex16((uint16_t)total);
    cputs("\n");
}
