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

static void put_dec16(int16_t v) {
    char buf[7];
    uint8_t i = 0, j;
    uint8_t neg = 0;
    int16_t n = v;
    if (n < 0) { neg = 1; n = -n; }
    if (n == 0) { buf[i++] = '0'; }
    else { while (n > 0) { buf[i++] = '0' + (n % 10); n /= 10; } }
    if (neg) buf[i++] = '-';
    { volatile uint8_t half = (uint8_t)(i >> 1); for (j = 0; j < half; j++) { char t=buf[j]; buf[j]=buf[i-1-j]; buf[i-1-j]=t; } }
    buf[i] = 0;
    cputs(buf);
}

/* status lines */
static void ok  (const char *name){ cputs("ok  ");  cputs(name); cputs("\n"); }
static void fail(const char *name){ cputs("FAIL "); cputs(name); cputs("\n"); }

/* ---------- "make value non-constant" helpers (C89/SDCC-safe) ---------- */

static uint8_t  mk_u8 (uint8_t  x){ volatile uint8_t  t=x; return t; }
static  int8_t  mk_s8 ( int8_t  x){ volatile  int8_t  t=x; return t; }
static uint16_t mk_u16(uint16_t x){ volatile uint16_t t=x; return t; }
static  int16_t mk_s16( int16_t x){ volatile  int16_t t=x; return t; }
static uint32_t mk_u32(uint32_t x){ volatile uint32_t t=x; return t; }
/* SDCC "long" is 32-bit; keep both typedefs for clarity */
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

#define _DEBUG 0

#if(_DEBUG)
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
#endif

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

/* ---------- int to float conversions ---------- */
static int test_uint2fs_zero(void) {
    const char *name = "(float)0u == +0.0f";
    unsigned int a = 0u;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x00000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_uint2fs_one(void) {
    const char *name = "(float)1u == 1.0f";
    unsigned int a = 1u;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x3F800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_uint2fs_32768(void) {
    const char *name = "(float)32768u == 32768.0f";
    unsigned int a = 32768u;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x47000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_uint2fs_65535(void) {
    const char *name = "(float)65535u == 65535.0f (exact)";
    unsigned int a = 65535u;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x477FFF00UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_sint2fs_pos_one(void) {
    const char *name = "(float)1 == 1.0f";
    int a = 1;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x3F800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_sint2fs_neg_one(void) {
    const char *name = "(float)-1 == -1.0f";
    int a = -1;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0xBF800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_sint2fs_min(void) {
    const char *name = "(float)-32768 == -32768.0f (exact)";
    int a = -32768;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0xC7000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_uchar2fs_zero(void) {
    const char *name = "(float)(unsigned char)0 == 0.0f";
    unsigned char a = 0;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x00000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_uchar2fs_one(void) {
    const char *name = "(float)(unsigned char)1 == 1.0f";
    unsigned char a = 1;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x3F800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_uchar2fs_255(void) {
    const char *name = "(float)(unsigned char)255 == 255.0f";
    unsigned char a = 255;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x437F0000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_schar2fs_zero(void) {
    const char *name = "(float)(signed char)0 == 0.0f";
    signed char a = 0;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x00000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_schar2fs_neg_one(void) {
    const char *name = "(float)(signed char)-1 == -1.0f";
    signed char a = (signed char)-1;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0xBF800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_schar2fs_min(void) {
    const char *name = "(float)(signed char)-128 == -128.0f";
    signed char a = (signed char)-128;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0xC3000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_schar2fs_127(void) {
    const char *name = "(float)(signed char)127 == 127.0f";
    signed char a = 127;
    float f = (float)a;
    uint32_t got = mk_u32(f32_bits(f));
    if (got == mk_u32(0x42FE0000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_ulong2fs_zero(void) {
    const char *name = "(float)0UL == +0.0f";
    unsigned long a = 0UL;
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0x00000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_ulong2fs_one(void) {
    const char *name = "(float)1UL == 1.0f";
    unsigned long a = 1UL;
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0x3F800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_ulong2fs_2p24_exact(void) {
    const char *name = "(float)16777216UL == 16777216.0f (exact)";
    unsigned long a = 16777216UL; /* 2^24 */
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0x4B800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_ulong2fs_round_2p24_plus1(void) {
    const char *name = "(float)16777217UL rounds to 16777216.0f";
    unsigned long a = 16777217UL; /* 2^24 + 1 */
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0x4B800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_ulong2fs_max_rounds_to_2p32(void) {
    const char *name = "(float)0xFFFFFFFFUL rounds to 4294967296.0f (2^32)";
    unsigned long a = 0xFFFFFFFFUL;
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0x4F800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_slong2fs_pos_one(void) {
    const char *name = "(float)1L == 1.0f";
    long a = 1L;
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0x3F800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_slong2fs_neg_one(void) {
    const char *name = "(float)-1L == -1.0f";
    long a = -1L;
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0xBF800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_slong2fs_min(void) {
    const char *name = "(float)-2147483648L == -2147483648.0f";
    long a = (long)0x80000000UL;
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0xCF000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_slong2fs_max_rounds_to_2p31(void) {
    const char *name = "(float)2147483647L rounds to 2147483648.0f";
    long a = 2147483647L;
    float f = (float)a;
    if (mk_u32(f32_bits(f)) == mk_u32(0x4F000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}


/* ---------- compares ---------- */
static int test_f32_lt_true(void) {
    const char *name = "f32 1.25 < 2.5 is true";
    float a = mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    float b = mk_f32(mk_u32(0x40200000UL));  /* 2.5 */
    int got = (a < b);
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_lt_false(void) {
    const char *name = "f32 2.5 < 1.25 is false";
    float a = mk_f32(mk_u32(0x40200000UL));  /* 2.5 */
    float b = mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    int got = (a < b);
    if (got == 0) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_lt_neg_true(void) {
    const char *name = "f32 -2.5 < 1.25 is true";
    float a = mk_f32(mk_u32(0xC0200000UL));  /* -2.5 */
    float b = mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    int got = (a < b);
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_eq_true(void) {
    const char *name = "f32 1.25 == 1.25 is true";
    float a = mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    float b = mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    int got = (a == b);
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_eq_false(void) {
    const char *name = "f32 1.25 == 2.5 is false";
    float a = mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    float b = mk_f32(mk_u32(0x40200000UL));  /* 2.5 */
    int got = (a == b);
    if (got == 0) { ok(name); return 1; }
    fail(name); return 0;
}

extern int __fscmp(float a, float b);

static int test_f32_cmp_basic_neg1(void) {
    const char *name = "fscmp 1.25 vs 2.5 == -1";
    float a = mk_f32(mk_u32(0x3FA00000UL));
    float b = mk_f32(mk_u32(0x40200000UL));
    int got = __fscmp(a, b);
    if (got == -1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_basic_zero(void) {
    const char *name = "fscmp 1.25 vs 1.25 == 0";
    float a = mk_f32(mk_u32(0x3FA00000UL));
    float b = mk_f32(mk_u32(0x3FA00000UL));
    int got = __fscmp(a, b);
    if (got == 0) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_basic_pos1(void) {
    const char *name = "fscmp 2.5 vs 1.25 == +1";
    float a = mk_f32(mk_u32(0x40200000UL));
    float b = mk_f32(mk_u32(0x3FA00000UL));
    int got = __fscmp(a, b);
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_same_exp_mant_neg1(void) {
    const char *name = "fscmp 1.25 vs 1.5 == -1 (same exp, mantissa)";
    float a = mk_f32(mk_u32(0x3FA00000UL)); /* 1.25 */
    float b = mk_f32(mk_u32(0x3FC00000UL)); /* 1.5 */
    int got = __fscmp(a, b);
    if (got == -1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_same_exp_mant_pos1(void) {
    const char *name = "fscmp 1.5 vs 1.25 == +1 (same exp, mantissa)";
    float a = mk_f32(mk_u32(0x3FC00000UL)); /* 1.5 */
    float b = mk_f32(mk_u32(0x3FA00000UL)); /* 1.25 */
    int got = __fscmp(a, b);
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_neg_vs_pos(void) {
    const char *name = "fscmp -1.25 vs 1.25 == -1";
    float a = mk_f32(mk_u32(0xBFA00000UL)); /* -1.25 */
    float b = mk_f32(mk_u32(0x3FA00000UL)); /* 1.25 */
    int got = __fscmp(a, b);
    if (got == -1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_both_negative(void) {
    const char *name = "fscmp -2.5 vs -1.25 == -1";
    float a = mk_f32(mk_u32(0xC0200000UL)); /* -2.5 */
    float b = mk_f32(mk_u32(0xBFA00000UL)); /* -1.25 */
    int got = __fscmp(a, b);
    if (got == -1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_neg_equal(void) {
    const char *name = "fscmp -1.25 vs -1.25 == 0";
    float a = mk_f32(mk_u32(0xBFA00000UL)); /* -1.25 */
    float b = mk_f32(mk_u32(0xBFA00000UL)); /* -1.25 */
    int got = __fscmp(a, b);
    if (got == 0) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_zero_vs_pos(void) {
    const char *name = "fscmp 0.0 vs 1.25 == -1";
    float a = mk_f32(mk_u32(0x00000000UL)); /* +0.0 */
    float b = mk_f32(mk_u32(0x3FA00000UL)); /* 1.25 */
    int got = __fscmp(a, b);
    if (got == -1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_zero_vs_neg(void) {
    const char *name = "fscmp 0.0 vs -1.25 == +1";
    float a = mk_f32(mk_u32(0x00000000UL)); /* +0.0 */
    float b = mk_f32(mk_u32(0xBFA00000UL)); /* -1.25 */
    int got = __fscmp(a, b);
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_neg_zero_vs_pos_zero(void) {
    const char *name = "fscmp -0.0 vs +0.0 == 0";
    float a = mk_f32(mk_u32(0x80000000UL)); /* -0.0 */
    float b = mk_f32(mk_u32(0x00000000UL)); /* +0.0 */
    int got = __fscmp(a, b);
    if (got == 0) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_denorm_vs_zero(void) {
    const char *name = "fscmp denormal vs 0.0 == 0 (denorms treated as 0)";
    float a = mk_f32(mk_u32(0x00000001UL)); /* smallest denormal */
    float b = mk_f32(mk_u32(0x00000000UL)); /* +0.0 */
    int got = __fscmp(a, b);
    if (got == 0) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_mant_lowbyte(void) {
    const char *name = "fscmp mantissa differs only in low byte";
    float a = mk_f32(mk_u32(0x3F800000UL)); /* 1.0 */
    float b = mk_f32(mk_u32(0x3F800001UL)); /* 1.0 + epsilon */
    int got = __fscmp(a, b);
    if (got == -1) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_cmp_large_vs_small(void) {
    const char *name = "fscmp 1000000.0 vs 0.000001";
    float a = mk_f32(mk_u32(0x49742400UL)); /* 1000000.0 */
    float b = mk_f32(mk_u32(0x358637BDUL)); /* ~0.000001 */
    int got = __fscmp(a, b);
    if (got == 1) { ok(name); return 1; }
    fail(name); return 0;
}

/* ---------- MUL ---------- */
static int test_f32_mul_basic_1(void) {
    const char *name = "fsmul 2.0 * 3.0 == 6.0";
    float a = mk_f32(mk_u32(0x40000000UL)); /* 2.0 */
    float b = mk_f32(mk_u32(0x40400000UL)); /* 3.0 */
    float expected = mk_f32(mk_u32(0x40C00000UL)); /* 6.0 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_basic_2(void) {
    const char *name = "fsmul 1.5 * 2.0 == 3.0";
    float a = mk_f32(mk_u32(0x3FC00000UL)); /* 1.5 */
    float b = mk_f32(mk_u32(0x40000000UL)); /* 2.0 */
    float expected = mk_f32(mk_u32(0x40400000UL)); /* 3.0 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_identity(void) {
    const char *name = "fsmul 5.25 * 1.0 == 5.25";
    float a = mk_f32(mk_u32(0x40A80000UL)); /* 5.25 */
    float b = mk_f32(mk_u32(0x3F800000UL)); /* 1.0 */
    float expected = mk_f32(mk_u32(0x40A80000UL)); /* 5.25 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_by_zero(void) {
    const char *name = "fsmul 5.25 * 0.0 == 0.0";
    float a = mk_f32(mk_u32(0x40A80000UL)); /* 5.25 */
    float b = mk_f32(mk_u32(0x00000000UL)); /* 0.0 */
    float expected = mk_f32(mk_u32(0x00000000UL)); /* 0.0 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_neg_pos(void) {
    const char *name = "fsmul -2.0 * 3.0 == -6.0";
    float a = mk_f32(mk_u32(0xC0000000UL)); /* -2.0 */
    float b = mk_f32(mk_u32(0x40400000UL)); /* 3.0 */
    float expected = mk_f32(mk_u32(0xC0C00000UL)); /* -6.0 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_neg_neg(void) {
    const char *name = "fsmul -2.0 * -3.0 == 6.0";
    float a = mk_f32(mk_u32(0xC0000000UL)); /* -2.0 */
    float b = mk_f32(mk_u32(0xC0400000UL)); /* -3.0 */
    float expected = mk_f32(mk_u32(0x40C00000UL)); /* 6.0 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_fraction(void) {
    const char *name = "fsmul 0.5 * 0.5 == 0.25";
    float a = mk_f32(mk_u32(0x3F000000UL)); /* 0.5 */
    float b = mk_f32(mk_u32(0x3F000000UL)); /* 0.5 */
    float expected = mk_f32(mk_u32(0x3E800000UL)); /* 0.25 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_small(void) {
    const char *name = "fsmul 0.1 * 0.1 == 0.01";
    float a = mk_f32(mk_u32(0x3DCCCCCDul)); /* ~0.1 */
    float b = mk_f32(mk_u32(0x3DCCCCCDul)); /* ~0.1 */
    float expected = mk_f32(mk_u32(0x3C23D70AUL)); /* ~0.01 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_large(void) {
    const char *name = "fsmul 1000.0 * 1000.0 == 1000000.0";
    float a = mk_f32(mk_u32(0x447A0000UL)); /* 1000.0 */
    float b = mk_f32(mk_u32(0x447A0000UL)); /* 1000.0 */
    float expected = mk_f32(mk_u32(0x49742400UL)); /* 1000000.0 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_pow2(void) {
    const char *name = "fsmul 4.0 * 8.0 == 32.0";
    float a = mk_f32(mk_u32(0x40800000UL)); /* 4.0 */
    float b = mk_f32(mk_u32(0x41000000UL)); /* 8.0 */
    float expected = mk_f32(mk_u32(0x42000000UL)); /* 32.0 */
    float got = __fsmul(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

/* ---------- DIV ---------- */
static int test_f32_div_basic_1(void) {
    const char *name = "fsdiv 6.0 / 3.0 == 2.0";
    float a = mk_f32(mk_u32(0x40C00000UL)); /* 6.0 */
    float b = mk_f32(mk_u32(0x40400000UL)); /* 3.0 */
    float expected = mk_f32(mk_u32(0x40000000UL)); /* 2.0 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_half(void) {
    const char *name = "fsdiv 1.0 / 2.0 == 0.5";
    float a = mk_f32(mk_u32(0x3F800000UL)); /* 1.0 */
    float b = mk_f32(mk_u32(0x40000000UL)); /* 2.0 */
    float expected = mk_f32(mk_u32(0x3F000000UL)); /* 0.5 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_10_by_5(void) {
    const char *name = "fsdiv 10.0 / 5.0 == 2.0";
    float a = mk_f32(mk_u32(0x41200000UL)); /* 10.0 */
    float b = mk_f32(mk_u32(0x40A00000UL)); /* 5.0 */
    float expected = mk_f32(mk_u32(0x40000000UL)); /* 2.0 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_pow2(void) {
    const char *name = "fsdiv 32.0 / 8.0 == 4.0";
    float a = mk_f32(mk_u32(0x42000000UL)); /* 32.0 */
    float b = mk_f32(mk_u32(0x41000000UL)); /* 8.0 */
    float expected = mk_f32(mk_u32(0x40800000UL)); /* 4.0 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_by_one(void) {
    const char *name = "fsdiv 7.0 / 1.0 == 7.0";
    float a = mk_f32(mk_u32(0x40E00000UL)); /* 7.0 */
    float b = mk_f32(mk_u32(0x3F800000UL)); /* 1.0 */
    float expected = mk_f32(mk_u32(0x40E00000UL)); /* 7.0 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_self(void) {
    const char *name = "fsdiv x / x == 1.0";
    float a = mk_f32(mk_u32(0x42F6E979UL)); /* ~123.456 */
    float b = mk_f32(mk_u32(0x42F6E979UL)); /* ~123.456 */
    float expected = mk_f32(mk_u32(0x3F800000UL)); /* 1.0 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_neg(void) {
    const char *name = "fsdiv -6.0 / 3.0 == -2.0";
    float a = mk_f32(mk_u32(0xC0C00000UL)); /* -6.0 */
    float b = mk_f32(mk_u32(0x40400000UL)); /* 3.0 */
    float expected = mk_f32(mk_u32(0xC0000000UL)); /* -2.0 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_small(void) {
    const char *name = "fsdiv 1.0 / 256.0 == 0.00390625";
    float a = mk_f32(mk_u32(0x3F800000UL)); /* 1.0 */
    float b = mk_f32(mk_u32(0x43800000UL)); /* 256.0 */
    float expected = mk_f32(mk_u32(0x3B800000UL)); /* 0.00390625 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_large(void) {
    const char *name = "fsdiv 1000000.0 / 1000.0 == 1000.0";
    float a = mk_f32(mk_u32(0x49742400UL)); /* 1000000.0 */
    float b = mk_f32(mk_u32(0x447A0000UL)); /* 1000.0 */
    float expected = mk_f32(mk_u32(0x447A0000UL)); /* 1000.0 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_zero_num(void) {
    const char *name = "fsdiv 0.0 / 5.0 == 0.0";
    float a = mk_f32(mk_u32(0x00000000UL)); /* 0.0 */
    float b = mk_f32(mk_u32(0x40A00000UL)); /* 5.0 */
    float expected = mk_f32(mk_u32(0x00000000UL)); /* 0.0 */
    float got = __fsdiv(a, b);
    if (mk_u32(got) == mk_u32(expected)) { ok(name); return 1; }
    fail(name); return 0;
}

/* ---------- additional MUL tests ---------- */
static int test_f32_mul_noshift(void) {
    const char *name = "fsmul 1.5 * 1.25 == 1.875";
    float a = mk_f32(mk_u32(0x3FC00000UL)); /* 1.5 */
    float b = mk_f32(mk_u32(0x3FA00000UL)); /* 1.25 */
    float got = __fsmul(a, b);
    if (f32_bits(got) == mk_u32(0x3FF00000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_small_large(void) {
    const char *name = "fsmul 0.00390625 * 256.0 == 1.0";
    float a = mk_f32(mk_u32(0x3B800000UL)); /* 2^-8 */
    float b = mk_f32(mk_u32(0x43800000UL)); /* 2^8 */
    float got = __fsmul(a, b);
    if (f32_bits(got) == mk_u32(0x3F800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_commutative(void) {
    const char *name = "fsmul 7.0 * 3.0 == 3.0 * 7.0";
    float a = mk_f32(mk_u32(0x40E00000UL)); /* 7.0 */
    float b = mk_f32(mk_u32(0x40400000UL)); /* 3.0 */
    float ab = __fsmul(a, b);
    float ba = __fsmul(b, a);
    if (f32_bits(ab) == f32_bits(ba)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_neg_by_zero(void) {
    const char *name = "fsmul -5.0 * 0.0 == 0.0";
    float a = mk_f32(mk_u32(0xC0A00000UL)); /* -5.0 */
    float b = mk_f32(mk_u32(0x00000000UL)); /* 0.0 */
    float got = __fsmul(a, b);
    if (f32_bits(got) == mk_u32(0x00000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_mul_square(void) {
    const char *name = "fsmul 16.0 * 16.0 == 256.0";
    float a = mk_f32(mk_u32(0x41800000UL)); /* 16.0 */
    float b = mk_f32(mk_u32(0x41800000UL)); /* 16.0 */
    float got = __fsmul(a, b);
    if (f32_bits(got) == mk_u32(0x43800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

/* ---------- additional DIV tests ---------- */
static int test_f32_div_neg_neg(void) {
    const char *name = "fsdiv -6.0 / -3.0 == 2.0";
    float a = mk_f32(mk_u32(0xC0C00000UL)); /* -6.0 */
    float b = mk_f32(mk_u32(0xC0400000UL)); /* -3.0 */
    float got = __fsdiv(a, b);
    if (f32_bits(got) == mk_u32(0x40000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_frac_result(void) {
    const char *name = "fsdiv 3.0 / 7.0 == ~0.42857143";
    float a = mk_f32(mk_u32(0x40400000UL)); /* 3.0 */
    float b = mk_f32(mk_u32(0x40E00000UL)); /* 7.0 */
    float got = __fsdiv(a, b);
    uint32_t gbits = f32_bits(got);
    if (gbits == mk_u32(0x3EDB6DB6UL) || gbits == mk_u32(0x3EDB6DB7UL)) { ok(name); return 1; }
    fail(name);
    cputs("  got: "); put_hex32(gbits); cputs("\n");
    return 0;
}

static int test_f32_div_by_half(void) {
    const char *name = "fsdiv 1.0 / 0.5 == 2.0";
    float a = mk_f32(mk_u32(0x3F800000UL)); /* 1.0 */
    float b = mk_f32(mk_u32(0x3F000000UL)); /* 0.5 */
    float got = __fsdiv(a, b);
    if (f32_bits(got) == mk_u32(0x40000000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_div_large_small(void) {
    const char *name = "fsdiv 65536.0 / 0.0625 == 1048576.0";
    float a = mk_f32(mk_u32(0x47800000UL)); /* 65536.0 */
    float b = mk_f32(mk_u32(0x3D800000UL)); /* 0.0625 = 2^-4 */
    float got = __fsdiv(a, b);
    if (f32_bits(got) == mk_u32(0x49800000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_muldiv_roundtrip(void) {
    const char *name = "fsdiv (4.0*8.0)/8.0 == 4.0";
    float a = mk_f32(mk_u32(0x40800000UL)); /* 4.0 */
    float b = mk_f32(mk_u32(0x41000000UL)); /* 8.0 */
    float prod = __fsmul(a, b);
    float got = __fsdiv(prod, b);
    if (f32_bits(got) == mk_u32(0x40800000UL)) { ok(name); return 1; }
    fail(name);
    cputs("  got: "); put_hex32(f32_bits(got)); cputs("\n");
    return 0;
}

static int test_f32_divmul_roundtrip(void) {
    const char *name = "fsmul (32.0/8.0)*8.0 == 32.0";
    float a = mk_f32(mk_u32(0x42000000UL)); /* 32.0 */
    float b = mk_f32(mk_u32(0x41000000UL)); /* 8.0 */
    float quot = __fsdiv(a, b);
    float got = __fsmul(quot, b);
    if (f32_bits(got) == mk_u32(0x42000000UL)) { ok(name); return 1; }
    fail(name);
    cputs("  got: "); put_hex32(f32_bits(got)); cputs("\n");
    return 0;
}

/* =========================================================================
 * Bug A: __sitof diagnostic — (float)(int) wrong for most non-zero ints
 *
 * sitof_check() casts a volatile int16_t and compares bits.
 * On failure it prints:  n=<decimal>  exp=0x<bits>  got=0x<bits>
 * This lets you see exactly which values fail and what bits come out,
 * pointing to the broken shift/normalise path in __sitof.
 * ========================================================================= */

static uint8_t sitof_check(int16_t n, uint32_t exp) {
    volatile int16_t v = n;
    uint32_t got = f32_bits((float)v);
    if (got == mk_u32(exp)) return 1;
    cputs("  n="); put_dec16(n);
    cputs(" exp=0x"); put_hex32(mk_u32(exp));
    cputs(" got=0x"); put_hex32(got); cputs("\n");
    return 0;
}

/* Positive powers of 2: each tests one normalisation shift distance */
static int test_sitof_pos_pow2(void) {
    const char *name = "sitof positive powers of 2 (1..16384)";
    uint8_t ok_flag = 1;
    ok_flag &= sitof_check(    1, 0x3F800000UL); /* exponent=127, shift 0  */
    ok_flag &= sitof_check(    2, 0x40000000UL); /* exponent=128, shift 1  */
    ok_flag &= sitof_check(    4, 0x40800000UL); /* exponent=129, shift 2  */
    ok_flag &= sitof_check(    8, 0x41000000UL); /* exponent=130, shift 3  */
    ok_flag &= sitof_check(   16, 0x41800000UL); /* exponent=131, shift 4  */
    ok_flag &= sitof_check(   32, 0x42000000UL); /* exponent=132, shift 5  */
    ok_flag &= sitof_check(   64, 0x42800000UL); /* exponent=133, shift 6  */
    ok_flag &= sitof_check(  128, 0x43000000UL); /* exponent=134, shift 7  */
    ok_flag &= sitof_check(  256, 0x43800000UL); /* exponent=135, shift 8  */
    ok_flag &= sitof_check(  512, 0x44000000UL); /* exponent=136, shift 9  */
    ok_flag &= sitof_check( 1024, 0x44800000UL); /* exponent=137, shift 10 */
    ok_flag &= sitof_check( 2048, 0x45000000UL); /* exponent=138, shift 11 */
    ok_flag &= sitof_check( 4096, 0x45800000UL); /* exponent=139, shift 12 */
    ok_flag &= sitof_check( 8192, 0x46000000UL); /* exponent=140, shift 13 */
    ok_flag &= sitof_check(16384, 0x46800000UL); /* exponent=141, shift 14 */
    if (ok_flag) { ok(name); return 1; }
    fail(name); return 0;
}

/* Non-power-of-2: exercises mantissa bits, split across both bytes */
static int test_sitof_mixed(void) {
    const char *name = "sitof mixed values (low-byte only vs both bytes)";
    uint8_t ok_flag = 1;
    /* value fits in low byte (MSB == 0x00) */
    ok_flag &= sitof_check(  3, 0x40400000UL);
    ok_flag &= sitof_check(  5, 0x40A00000UL);
    ok_flag &= sitof_check(  7, 0x40E00000UL);
    ok_flag &= sitof_check( 10, 0x41200000UL);
    ok_flag &= sitof_check( 15, 0x41700000UL);
    ok_flag &= sitof_check(100, 0x42C80000UL);
    ok_flag &= sitof_check(127, 0x42FE0000UL);
    ok_flag &= sitof_check(200, 0x43480000UL);
    ok_flag &= sitof_check(255, 0x437F0000UL);
    /* value spans both bytes (MSB != 0x00) */
    ok_flag &= sitof_check( 257, 0x43808000UL);
    ok_flag &= sitof_check( 300, 0x43960000UL);
    ok_flag &= sitof_check(1000, 0x447A0000UL);
    ok_flag &= sitof_check(1023, 0x447FC000UL);
    ok_flag &= sitof_check(32767,0x46FFFE00UL);
    if (ok_flag) { ok(name); return 1; }
    fail(name); return 0;
}

/* Negative values: exercises sign handling + normalisation */
static int test_sitof_negative(void) {
    const char *name = "sitof negative values";
    uint8_t ok_flag = 1;
    ok_flag &= sitof_check(   -1, 0xBF800000UL);
    ok_flag &= sitof_check(   -2, 0xC0000000UL);
    ok_flag &= sitof_check(   -4, 0xC0800000UL);
    ok_flag &= sitof_check(   -8, 0xC1000000UL);
    ok_flag &= sitof_check( -100, 0xC2C80000UL);
    ok_flag &= sitof_check( -128, 0xC3000000UL);
    ok_flag &= sitof_check( -255, 0xC37F0000UL);
    ok_flag &= sitof_check( -256, 0xC3800000UL);
    ok_flag &= sitof_check(-1000, 0xC47A0000UL);
    ok_flag &= sitof_check(-32768,0xC7000000UL);
    if (ok_flag) { ok(name); return 1; }
    fail(name); return 0;
}

/* =========================================================================
 * Bug B: __fsdiv x/x diagnostic
 *
 * Two sub-cases to distinguish aliasing from value issues:
 *   same_var:  float x = mk_f32(...); __fsdiv(x, x)   <- the failing case
 *   two_vars:  float a = mk_f32(...); float b = mk_f32(...); __fsdiv(a, b)
 *
 * The bit dump always runs and prints what __fsdiv(x,x) actually returns,
 * giving enough info to find the corrupted intermediate in the asm.
 * ========================================================================= */

static uint8_t fsdiv_self_check(uint32_t bits) {
    float x = mk_f32(bits);
    float got = __fsdiv(x, x);
    uint32_t got_bits = f32_bits(got);
    if (got_bits == mk_u32(0x3F800000UL)) return 1;
    cputs("  x=0x"); put_hex32(bits);
    cputs(" -> 0x"); put_hex32(got_bits); cputs(" (exp 3F800000)\n");
    return 0;
}

static uint8_t fsdiv_twovar_check(uint32_t bits) {
    float a = mk_f32(bits);
    float b = mk_f32(bits);
    float got = __fsdiv(a, b);
    uint32_t got_bits = f32_bits(got);
    if (got_bits == mk_u32(0x3F800000UL)) return 1;
    cputs("  x=0x"); put_hex32(bits);
    cputs(" -> 0x"); put_hex32(got_bits); cputs(" (exp 3F800000)\n");
    return 0;
}

/* __fsdiv(x, x) — same variable for both args */
static int test_fsdiv_same_var(void) {
    const char *name = "fsdiv x/x same variable";
    uint8_t ok_flag = 1;
    ok_flag &= fsdiv_self_check(0x3F800000UL); /*  1.0 */
    ok_flag &= fsdiv_self_check(0xBF800000UL); /* -1.0 */
    ok_flag &= fsdiv_self_check(0x40000000UL); /*  2.0 */
    ok_flag &= fsdiv_self_check(0xC0000000UL); /* -2.0 */
    ok_flag &= fsdiv_self_check(0x3F000000UL); /*  0.5 */
    ok_flag &= fsdiv_self_check(0x42C80000UL); /*  100.0 */
    ok_flag &= fsdiv_self_check(0x447A0000UL); /*  1000.0 */
    ok_flag &= fsdiv_self_check(0x42F6E979UL); /* ~123.456 */
    if (ok_flag) { ok(name); return 1; }
    fail(name); return 0;
}

/* __fsdiv(a, b) — two separate variables, equal value (baseline) */
static int test_fsdiv_two_vars(void) {
    const char *name = "fsdiv a/b two vars equal value";
    uint8_t ok_flag = 1;
    ok_flag &= fsdiv_twovar_check(0x3F800000UL); /*  1.0 */
    ok_flag &= fsdiv_twovar_check(0xBF800000UL); /* -1.0 */
    ok_flag &= fsdiv_twovar_check(0x40000000UL); /*  2.0 */
    ok_flag &= fsdiv_twovar_check(0xC0000000UL); /* -2.0 */
    ok_flag &= fsdiv_twovar_check(0x3F000000UL); /*  0.5 */
    ok_flag &= fsdiv_twovar_check(0x42C80000UL); /*  100.0 */
    ok_flag &= fsdiv_twovar_check(0x447A0000UL); /*  1000.0 */
    ok_flag &= fsdiv_twovar_check(0x42F6E979UL); /* ~123.456 */
    if (ok_flag) { ok(name); return 1; }
    fail(name); return 0;
}

/* Always passes — prints what __fsdiv(x,x) actually returns per value */
static int test_fsdiv_same_var_dump(void) {
    const char *name = "fsdiv x/x bit dump (informational)";
    uint32_t cases[] = {
        0x3F800000UL,  /*  1.0 */
        0xBF800000UL,  /* -1.0 */
        0x40000000UL,  /*  2.0 */
        0x40400000UL,  /*  3.0 */
        0x40800000UL,  /*  4.0 */
        0x41000000UL,  /*  8.0 */
        0x3F000000UL,  /*  0.5 */
        0x3E800000UL,  /*  0.25 */
        0x42C80000UL,  /*  100.0 */
        0x447A0000UL,  /*  1000.0 */
    };
    uint8_t i;
    for (i = 0; i < 10; i++) {
        float x = mk_f32(cases[i]);
        uint32_t got = f32_bits(__fsdiv(x, x));
        cputs("  0x"); put_hex32(cases[i]);
        cputs("/same -> 0x"); put_hex32(got);
        cputs(got == mk_u32(0x3F800000UL) ? " ok\n" : " WRONG\n");
    }
    ok(name); return 1;
}

/* =========================================================================
 * Previous bug regression tests (from libcpm3-z80 session)
 * ========================================================================= */

static int test_fsdiv_one_over_one(void) {
    const char *name = "fsdiv 1.0/1.0 == 1.0 (two vars)";
    float a = mk_f32(mk_u32(0x3F800000UL));
    float b = mk_f32(mk_u32(0x3F800000UL));
    float got = __fsdiv(a, b);
    if (f32_bits(got) == mk_u32(0x3F800000UL)) { ok(name); return 1; }
    cputs("FAIL "); cputs(name); cputs(" got=0x"); put_hex32(f32_bits(got)); cputs("\n");
    return 0;
}

static int test_fsdiv_neg_over_neg(void) {
    const char *name = "fsdiv -1.0/-1.0 == 1.0 (two vars)";
    float a = mk_f32(mk_u32(0xBF800000UL));
    float b = mk_f32(mk_u32(0xBF800000UL));
    float got = __fsdiv(a, b);
    if (f32_bits(got) == mk_u32(0x3F800000UL)) { ok(name); return 1; }
    cputs("FAIL "); cputs(name); cputs(" got=0x"); put_hex32(f32_bits(got)); cputs("\n");
    return 0;
}

static int test_ltof_runtime_long(void) {
    const char *name = "ltof (float)(acc of 100x 1L) == 100.0";
    long acc = 0;
    uint8_t i;
    for (i = 0; i < 100; i++)
        acc += mk_s32(1L);
    float r = (float)acc;
    uint32_t got = f32_bits(r);
    if (got == mk_u32(0x42C80000UL)) { ok(name); return 1; }
    cputs("FAIL "); cputs(name); cputs(" got=0x"); put_hex32(got); cputs("\n");
    return 0;
}

/* ---------- main -------------------------------------------------------- */

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
    total++; passed += test_fs2ulong_word_order_sentinel();
    total++; passed += test_uint2fs_zero();
    total++; passed += test_uint2fs_one();
    total++; passed += test_uint2fs_32768();
    total++; passed += test_uint2fs_65535();
    total++; passed += test_sint2fs_pos_one();
    total++; passed += test_sint2fs_neg_one();
    total++; passed += test_sint2fs_min();
    total++; passed += test_uchar2fs_zero();
    total++; passed += test_uchar2fs_one();
    total++; passed += test_uchar2fs_255();
    total++; passed += test_schar2fs_zero();
    total++; passed += test_schar2fs_neg_one();
    total++; passed += test_schar2fs_min();
    total++; passed += test_schar2fs_127();
    total++; passed += test_ulong2fs_zero();
    total++; passed += test_ulong2fs_one();
    total++; passed += test_ulong2fs_2p24_exact();
    total++; passed += test_ulong2fs_round_2p24_plus1();
    total++; passed += test_ulong2fs_max_rounds_to_2p32();
    total++; passed += test_slong2fs_pos_one();
    total++; passed += test_slong2fs_neg_one();
    total++; passed += test_slong2fs_min();
    total++; passed += test_slong2fs_max_rounds_to_2p31();
    total++; passed += test_f32_cmp_basic_neg1();
    total++; passed += test_f32_cmp_basic_zero();
    total++; passed += test_f32_cmp_basic_pos1();
    total++; passed += test_f32_cmp_same_exp_mant_pos1();
    total++; passed += test_f32_cmp_same_exp_mant_neg1();
    total++; passed += test_f32_cmp_neg_vs_pos();
    total++; passed += test_f32_cmp_both_negative();
    total++; passed += test_f32_cmp_neg_equal();
    total++; passed += test_f32_cmp_zero_vs_pos();
    total++; passed += test_f32_cmp_zero_vs_neg();
    total++; passed += test_f32_cmp_neg_zero_vs_pos_zero();
    total++; passed += test_f32_cmp_denorm_vs_zero();
    total++; passed += test_f32_cmp_mant_lowbyte();
    total++; passed += test_f32_cmp_large_vs_small();
    total++; passed += test_f32_lt_false();
    total++; passed += test_f32_lt_neg_true();
    total++; passed += test_f32_eq_false();
    total++; passed += test_f32_lt_true();
    total++; passed += test_f32_eq_true();
    total++; passed += test_f32_mul_basic_1();
    total++; passed += test_f32_mul_basic_2();
    total++; passed += test_f32_mul_identity();
    total++; passed += test_f32_mul_by_zero();
    total++; passed += test_f32_mul_neg_pos();
    total++; passed += test_f32_mul_neg_neg();
    total++; passed += test_f32_mul_fraction();
    total++; passed += test_f32_mul_small();
    total++; passed += test_f32_mul_large();
    total++; passed += test_f32_mul_pow2();
    total++; passed += test_f32_div_basic_1();
    total++; passed += test_f32_div_half();
    total++; passed += test_f32_div_10_by_5();
    total++; passed += test_f32_div_pow2();
    total++; passed += test_f32_div_by_one();
    total++; passed += test_f32_div_self();
    total++; passed += test_f32_div_neg();
    total++; passed += test_f32_div_small();
    total++; passed += test_f32_div_zero_num();
    total++; passed += test_f32_div_large();
    total++; passed += test_f32_mul_noshift();
    total++; passed += test_f32_mul_small_large();
    total++; passed += test_f32_mul_commutative();
    total++; passed += test_f32_mul_neg_by_zero();
    total++; passed += test_f32_mul_square();
    total++; passed += test_f32_div_neg_neg();
    total++; passed += test_f32_div_frac_result();
    total++; passed += test_f32_div_by_half();
    total++; passed += test_f32_div_large_small();
    total++; passed += test_f32_muldiv_roundtrip();
    total++; passed += test_f32_divmul_roundtrip();

    /* --- Bug A: __sitof (int->float) diagnostic --- */
    total++; passed += test_sitof_pos_pow2();
    total++; passed += test_sitof_mixed();
    total++; passed += test_sitof_negative();

    /* --- Bug B: __fsdiv x/x diagnostic --- */
    total++; passed += test_fsdiv_same_var();
    total++; passed += test_fsdiv_two_vars();
    total++; passed += test_fsdiv_same_var_dump(); /* informational, always passes */

    /* --- previous regression tests --- */
    total++; passed += test_fsdiv_one_over_one();
    total++; passed += test_fsdiv_neg_over_neg();
    total++; passed += test_ltof_runtime_long();

#if(_DEBUG)
    dump_fdebug();
#endif

    cputs("Summary: ");
    put_hex16((uint16_t)passed);
    cputc('/');
    put_hex16((uint16_t)total);
    cputs("\n");
}
