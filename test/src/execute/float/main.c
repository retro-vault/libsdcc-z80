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


/* ---------- initial float tests ---------- */

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

static int test_f32_mul_basic(void) {
    const char *name = "f32 1.25 * (-2.5) == -3.125";
    float a = mk_f32(mk_u32(0x3FA00000UL));  /* 1.25 */
    float b = mk_f32(mk_u32(0xC0200000UL));  /* -2.5 */
    float r = a * b;                          /* ___fsmul */
    if (mk_u32(f32_bits(r)) == mk_u32(0xC0480000UL)) { ok(name); return 1; } /* -3.125 */
    fail(name); return 0;
}

static int test_f32_div_basic(void) {
    const char *name = "f32 3.0 / 2.0 == 1.5";
    float a = mk_f32(mk_u32(0x40400000UL));  /* 3.0 */
    float b = mk_f32(mk_u32(0x40000000UL));  /* 2.0 */
    float r = a / b;                          /* ___fsdiv */
    if (mk_u32(f32_bits(r)) == mk_u32(0x3FC00000UL)) { ok(name); return 1; } /* 1.5 */
    fail(name); return 0;
}

static int test_f32_unary_sign(void) {
    const char *name = "f32 unary +/-, -(-2.5)==2.5";
    float b = mk_f32(mk_u32(0xC0200000UL));  /* -2.5 */
    float r = -b;                             /* sign op */
    if (mk_u32(f32_bits(r)) == mk_u32(0x40200000UL)) { ok(name); return 1; } /* +2.5 */
    fail(name); return 0;
}

static int test_f32_cmp_basic(void) {
    const char *name = "f32 comparisons 1.0<2.0, 2.0>1.0, 1.0==1.0";
    float a = mk_f32(mk_u32(0x3F800000UL));  /* 1.0 */
    float b = mk_f32(mk_u32(0x40000000UL));  /* 2.0 */
    int r = 0;

    r += (a <  b);
    r += (b >  a);
    r += (a == a);
    r += (a != b);

    if (r == 4) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_to_s16_trunc(void) {
    const char *name = "s16 (int)-2.5 trunc toward zero == -2";
    float a = mk_f32(mk_u32(0xC0200000UL));       /* -2.5 */
    int16_t r = (int16_t)(int)a;                  /* ___fs2sint path */
    if (r == (int16_t)-2) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_f32_to_u16(void) {
    const char *name = "u16 (unsigned)40000.0 == 40000";
    float a = mk_f32(mk_u32(0x471C4000UL));       /* 40000.0 */
    uint16_t r = (uint16_t)(unsigned)a;           /* ___fs2uint path */
    if (r == (uint16_t)40000u) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_s16_to_f32_bits(void) {
    const char *name = "f32 (float)-456 == 0xC3E40000";
    int16_t i = (int16_t)mk_s16(-456);
    float r = (float)i;                           /* ___sint2fs path */
    if (mk_u32(f32_bits(r)) == mk_u32(0xC3E40000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_u16_to_f32_bits(void) {
    const char *name = "f32 (float)40000u == 0x471C4000";
    uint16_t u = (uint16_t)mk_u16(40000u);
    float r = (float)u;                           /* ___uint2fs path */
    if (mk_u32(f32_bits(r)) == mk_u32(0x471C4000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_s32_to_f32_bits(void) {
    const char *name = "f32 (float)123456L == 0x47F12000";
    int32_t i = mk_s32(123456L);
    float r = (float)i;                           /* ___slong2fs */
    if (mk_u32(f32_bits(r)) == mk_u32(0x47F12000UL)) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_u32_to_f32_bits(void) {
    const char *name = "f32 (float)345678UL == 0x48A8C9C0";
    uint32_t u = mk_u32(345678UL);
    float r = (float)u;                           /* ___ulong2fs */
    if (mk_u32(f32_bits(r)) == mk_u32(0x48A8C9C0UL)) { ok(name); return 1; }
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

    dump_fdebug();

    //total++; passed += test_f32_mul_basic();
    //total++; passed += test_f32_div_basic();
    //total++; passed += test_f32_unary_sign();
    //total++; passed += test_f32_cmp_basic();
    //total++; passed += test_f32_to_s16_trunc();
    //total++; passed += test_f32_to_u16();
    //total++; passed += test_s16_to_f32_bits();
    //total++; passed += test_u16_to_f32_bits();
    //total++; passed += test_s32_to_f32_bits();
    //total++; passed += test_u32_to_f32_bits();


    cputs("Summary: ");
    put_hex16((uint16_t)passed);
    cputc('/');
    put_hex16((uint16_t)total);
    cputs("\n");
}
