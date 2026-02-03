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
    //total++; passed += test_f32_cmp_basic_neg1();
    //total++; passed += test_f32_cmp_basic_zero();
    //total++; passed += test_f32_cmp_basic_pos1();
    //total++; passed += test_f32_cmp_same_exp_mant_pos1();
    //total++; passed += test_f32_cmp_same_exp_mant_neg1();

    //total++; passed += test_f32_lt_true();
    total++; passed += test_f32_lt_false();
    //total++; passed += test_f32_lt_neg_true();
    //total++; passed += test_f32_eq_true();
    //total++; passed += test_f32_eq_false();


    dump_fdebug();

    cputs("Summary: ");
    put_hex16((uint16_t)passed);
    cputc('/');
    put_hex16((uint16_t)total);
    cputs("\n");
}
