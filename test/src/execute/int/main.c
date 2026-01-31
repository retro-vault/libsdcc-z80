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

/* ---------- “make value non-constant” helpers (C89/SDCC-safe) ---------- */

static uint8_t  mk_u8 (uint8_t  x){ volatile uint8_t  t=x; return t; }
static  int8_t  mk_s8 ( int8_t  x){ volatile  int8_t  t=x; return t; }
static uint16_t mk_u16(uint16_t x){ volatile uint16_t t=x; return t; }
static  int16_t mk_s16( int16_t x){ volatile  int16_t t=x; return t; }
static uint32_t mk_u32(uint32_t x){ volatile uint32_t t=x; return t; }
/* SDCC “long” is 32-bit; keep both typedefs for clarity */
static  int32_t mk_s32( int32_t x){ volatile  int32_t t=x; return t; }

/* status lines */
static void ok  (const char *name){ cputs("ok  ");  cputs(name); cputs("\n"); }
static void fail(const char *name){ cputs("FAIL "); cputs(name); cputs("\n"); }

/* ---------- u8 / s8 ---------- */

static int test_u8_wrap_add(void){
    const char *name="u8 250+10==4";
    uint8_t a=mk_u8(250), b=mk_u8(10), r=(uint8_t)(a+b);
    if(r==4) { ok(name); return 1; } fail(name); return 0;
}
static int test_s8_cmp(void){
    const char *name="<s8> -5<3";
    int8_t a=mk_s8(-5), b=mk_s8(3);
    if(a<b) { ok(name); return 1; } fail(name); return 0;
}

/* ---------- u16 / s16 core arithmetic ---------- */

static int test_u16_add(void){
    const char *name="u16 1234+4321==5555";
    uint16_t a=mk_u16(1234), b=mk_u16(4321), r=(uint16_t)(a+b);
    if(r==5555u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_sub(void){
    const char *name="u16 7000-1234==5766";
    uint16_t a=mk_u16(7000), b=mk_u16(1234), r=(uint16_t)(a-b);
    if(r==5766u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_mul(void){
    const char *name="u16 123*45==5535";
    uint16_t a=mk_u16(123), b=mk_u16(45), r=(uint16_t)(a*b);
    if(r==5535u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_div(void){
    const char *name="u16 5000/125==40";
    uint16_t a=mk_u16(5000), b=mk_u16(125), r=(uint16_t)(a/b);
    if(r==40u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_mod(void){
    const char *name="u16 5010%125==10";
    uint16_t a=mk_u16(5010), b=mk_u16(125), r=(uint16_t)(a%b);
    if(r==10u){ ok(name); return 1; } fail(name); return 0;
}
static int test_s16_mul(void){
    const char *name="s16 -123*45==-5535";
    int16_t a=mk_s16(-123), b=mk_s16(45), r=(int16_t)(a*b);
    if(r==(int16_t)-5535){ ok(name); return 1; } fail(name); return 0;
}
static int test_s16_div(void){
    const char *name="s16 -30000/1000==-30";
    int16_t a=mk_s16(-30000), b=mk_s16(1000), r=(int16_t)(a/b);
    if(r==(int16_t)-30){ ok(name); return 1; } fail(name); return 0;
}
static int test_s16_mod(void){
    const char *name="s16 -30000%1000==0";
    int16_t a=mk_s16(-30000), b=mk_s16(1000), r=(int16_t)(a%b);
    if(r==0){ ok(name); return 1; } fail(name); return 0;
}

/* ---------- shifts ---------- */

static int test_u16_shl(void){
    const char *name="u16 0x1234<<3==0x91A0";
    uint16_t r=(uint16_t)(mk_u16(0x1234u)<<mk_u16(3));
    if(r==0x91A0u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_shr(void){
    const char *name="u16 0x8001>>3==0x1000";
    uint16_t r=(uint16_t)(mk_u16(0x8001u)>>mk_u16(3));
    if(r==0x1000u){ ok(name); return 1; } fail(name); return 0;
}
static int test_s16_sar(void){
    const char *name="s16 0x8000>>1==0xC000";
    int16_t x = mk_s16((int16_t)-32768);      /* == 0x8000 as s16 */
    int16_t r = (int16_t)(x >> mk_u16(1));    /* arithmetic shift */
    if ((uint16_t)r == 0xC000u) { ok(name); return 1; }
    fail(name); return 0;
}

/* ---------- comparisons ---------- */

static int test_u16_cmp(void){
    const char *n1="u16 1000<2000";
    const char *n2="u16 3000==3000";
    int okall=1;
    if(mk_u16(1000)<mk_u16(2000)) ok(n1); else { fail(n1); okall=0; }
    if(mk_u16(3000)==mk_u16(3000)) ok(n2); else { fail(n2); okall=0; }
    return okall;
}
static int test_s16_cmp(void){
    const char *n1="s16 -2<1";
    const char *n2="s16 -2!=-1";
    int okall=1;
    if(mk_s16(-2)<mk_s16(1)) ok(n1); else { fail(n1); okall=0; }
    if(mk_s16(-2)!=mk_s16(-1)) ok(n2); else { fail(n2); okall=0; }
    return okall;
}

/* ---------- u32 / s32 (use 32-bit “long” in SDCC) ---------- */

static int test_u32_mul(void){
    const char *name="u32 70000*3==210000";
    uint32_t r=(uint32_t)(mk_u32(70000uL)*mk_u32(3u));
    if(r==210000uL){ ok(name); return 1; } fail(name); return 0;
}

static int test_s32_divmod(void){
    const char *n1="s32 -1000000/3==-333333";
    const char *n2="s32 -1000000%3==-1";
    int32_t a=mk_s32(-1000000);
    int32_t q=a/mk_s32(3);
    int32_t m=a%mk_s32(3);
    int okall=1;
    if(q==(int32_t)-333333) ok(n1); else { fail(n1); okall=0; }
    if(m==(int32_t)-1)      ok(n2); else { fail(n2); okall=0; }
    return okall;
}
static int test_u32_shifts(void){
    const char *n1="u32 12345678<<4==23456780";
    const char *n2="u32 12345678>>4==01234567";
    uint32_t x=mk_u32(0x12345678UL);
    int okall=1;
    if( (x<<mk_u32(4)) == 0x23456780UL ) ok(n1); else { fail(n1); okall=0; }
    if( (x>>mk_u32(4)) == 0x01234567UL ) ok(n2); else { fail(n2); okall=0; }
    return okall;
}
static int test_s32_cmp(void){
    const char *n1="s32 -5<2";
    const char *n2="u32 4e9>3e9";
    int okall=1;
    if(mk_s32(-5) < mk_s32(2)) ok(n1); else { fail(n1); okall=0; }
    if(mk_u32(4000000000uL) > mk_u32(3000000000uL)) ok(n2); else { fail(n2); okall=0; }
    return okall;
}

/* ---------- conversions ---------- */

static int test_sext8_to_s16(void){
    const char *name="sext (int8)0x80->0xFF80";
    int16_t r=(int16_t)(int8_t)mk_s8(0x80);
    if((uint16_t)r==0xFF80u){ ok(name); return 1; } fail(name); return 0;
}
static int test_zext8_to_u16(void){
    const char *name="zext (uint8)0x80->0x0080";
    uint16_t r=(uint16_t)(uint8_t)mk_u8(0x80);
    if(r==0x0080u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_u32_roundtrip(void){
    const char *name="u16->u32->u16 65535";
    uint16_t u  = mk_u16(65535u);
    uint32_t w  = mk_u32((uint32_t)u);      /* volatile barrier */
    uint16_t u2 = mk_u16((uint16_t)w);      /* volatile barrier */
    if (u2 == u) { ok(name); return 1; }    /* won’t be folded */
    fail(name); return 0;
}
/* ---- u8 shifts & bitwise ---- */
static int test_u8_shl(void){
    const char *name="u8 0x81<<1==0x02";
    uint8_t r = (uint8_t)(mk_u8(0x81) << mk_u8(1));
    if (r == (uint8_t)0x02) { ok(name); return 1; } fail(name); return 0;
}
static int test_u8_shr(void){
    const char *name="u8 0x81>>1==0x40";
    uint8_t r = (uint8_t)(mk_u8(0x81) >> mk_u8(1));
    if (r == (uint8_t)0x40) { ok(name); return 1; } fail(name); return 0;
}
static int test_u8_bits(void){
    const char *name="u8 (0xAA&0x0F)^(0xF0|0x01)==0xFB";
    uint8_t r = (uint8_t)((mk_u8(0xAA)&mk_u8(0x0F)) ^ (mk_u8(0xF0)|mk_u8(0x01)));
    if (r == (uint8_t)0xFB) { ok(name); return 1; } fail(name); return 0;
}

/* ---- u16 wrap/borrow edges ---- */
static int test_u16_inc_wrap(void){
    const char *name="u16 0xFFFF+1==0x0000";
    uint16_t r = (uint16_t)(mk_u16(0xFFFF) + mk_u16(1));
    if (r == 0x0000u) { ok(name); return 1; } fail(name); return 0;
}
static int test_u16_dec_wrap(void){
    const char *name="u16 0x0000-1==0xFFFF";
    uint16_t r = (uint16_t)(mk_u16(0x0000) - mk_u16(1));
    if (r == 0xFFFFu) { ok(name); return 1; } fail(name); return 0;
}
static int test_u16_bits(void){
    const char *name="u16 (0x1234&0x0F0F)|(0x00F0^0x0FF0)==0x0F04";
    uint16_t r = (uint16_t)((mk_u16(0x1234)&mk_u16(0x0F0F)) | (mk_u16(0x00F0)^mk_u16(0x0FF0)));
    if (r == 0x0F04u) { ok(name); return 1; } fail(name); return 0;
}

/* ---- s16 neg & abs-like sanity (no UB) ---- */
static int test_s16_neg(void){
    const char *name="s16 -(+1234)==-1234";
    int16_t r = (int16_t)(-mk_s16(+1234));
    if (r == (int16_t)-1234) { ok(name); return 1; } fail(name); return 0;
}

/* ---- 32-bit helpers and edges ---- */
static int test_u32_add_carry(void){
    const char *name="u32 0xFFFFFFFF+1==0";
    uint32_t r = (uint32_t)(mk_u32(0xFFFFFFFFUL) + mk_u32(1UL));
    if (r == 0UL) { ok(name); return 1; } fail(name); return 0;
}
static int test_u32_sub_borrow(void){
    const char *name="u32 0-1==0xFFFFFFFF";
    uint32_t r = (uint32_t)(mk_u32(0UL) - mk_u32(1UL));
    if (r == 0xFFFFFFFFUL) { ok(name); return 1; } fail(name); return 0;
}
static int test_s32_sar(void){
    const char *name="s32 0x80000000>>1==0xC0000000";
    int32_t  x = mk_s32((int32_t)0x80000000UL);
    int32_t  r = (int32_t)(x >> mk_u32(1));
    if ((uint32_t)r == 0xC0000000UL) { ok(name); return 1; } fail(name); return 0;
}

/* ---- 32 ---- */
static int test_u16x_u16_to_u32(void){
    const char *name="(u16)60000*(u16)1000 -> u32 60000000";
    uint16_t a = mk_u16(60000u);
    uint16_t b = mk_u16(1000u);
    uint32_t r = (uint32_t)mk_u32((uint32_t)a) * (uint32_t)mk_u32((uint32_t)b);
    if (r == 60000000UL) { ok(name); return 1; } fail(name); return 0;
}

static int test_u32_bits(void){
    const char *name="u32 (12345678&00FF00FF)^(0000FFFF|FF000000)==FF34FF87";
    uint32_t r = (mk_u32(0x12345678UL)&mk_u32(0x00FF00FFUL)) ^
                 (mk_u32(0x0000FFFFUL)|mk_u32(0xFF000000UL));
    if (r == 0xFF34FF87UL) { ok(name); return 1; } fail(name); return 0;
}

static int test_u32_divmod(void){
    const char *n1="u32 1000000/3==333333";
    const char *n2="u32 1000000%3==1";
    uint32_t a=mk_u32(1000000uL);
    uint32_t q=a/mk_u32(3u);
    uint32_t m=a%mk_u32(3u);
    int okall=1;
    if(q==333333uL) ok(n1); else { fail(n1); okall=0; }
    if(m==1u)       ok(n2); else { fail(n2); okall=0; }
    return okall;
}


/* Additional integer tests for SDCC integer behaviour (append to suite) */

static int test_u32_mul_wrap(void){
    const char *name="u32 0xFFFFFFFF*2==0xFFFFFFFE";
    uint32_t r = (uint32_t)(mk_u32(0xFFFFFFFFUL) * mk_u32(2UL));
    if (r == 0xFFFFFFFEUL) { ok(name); return 1; } fail(name); return 0;
}

static int test_s32_mul_neg(void){
    const char *name="s32 -200000*2000==-400000000";
    int32_t r = (int32_t)(mk_s32(-200000) * mk_s32(2000));
    if (r == (int32_t)-400000000) { ok(name); return 1; } fail(name); return 0;
}

static int test_mixed_signed_unsigned_cmp(void){
    const char *name="s32 -1 < u32 1 -> false";
    /* -1 promoted to unsigned -> large, so comparison should be false */
    if (!(mk_s32(-1) < mk_u32(1u))) { ok(name); return 1; } fail(name); return 0;
}

static int test_signed_plus_unsigned_arith(void){
    const char *name="s32 -1 + u32 2 == u32 1";
    /* mixed arithmetic: signed converted to unsigned, result unsigned */
    uint32_t r = (uint32_t)(mk_s32(-1) + mk_u32(2u));
    if (r == 1u) { ok(name); return 1; } fail(name); return 0;
}

static int test_u16_compound_assign_wrap(void){
    const char *name="u16 0xFF00 += 0x0200 -> 0x0100 (wrap)";
    uint16_t x = mk_u16(0xFF00u);
    x += mk_u16(0x0200u); /* promoted, then assigned back with wrap */
    if (x == 0x0100u) { ok(name); return 1; } fail(name); return 0;
}

static int test_s16_div_compound(void){
    const char *name="s16 -3 /= 2 -> -1 (trunc toward zero)";
    int16_t y = mk_s16(-3);
    y /= mk_s16(2);
    if (y == (int16_t)-1) { ok(name); return 1; } fail(name); return 0;
}

static int test_bitwise_not_u32(void){
    const char *name="u32 ~0 == 0xFFFFFFFF";
    uint32_t r = (uint32_t)(~mk_u32(0u));
    if (r == 0xFFFFFFFFUL) { ok(name); return 1; } fail(name); return 0;
}

static int test_u16_shift_large(void){
    const char *name="u16 (1<<15)==0x8000 (promotion rules)";
    uint16_t r = (uint16_t)(mk_u16(1) << mk_u16(15));
    if (r == 0x8000u) { ok(name); return 1; } fail(name); return 0;
}



static int test_s32_mod_negative_small(void){
    const char *name="s32 -7%3 == -1";
    int32_t r = (int32_t)(mk_s32(-7) % mk_s32(3));
    if (r == (int32_t)-1) { ok(name); return 1; } fail(name); return 0;
}


/* ---------- Division & Modulo edge cases (very important for runtime libs) ---------- */

/* Division by zero – SDCC usually calls a handler or traps, but test that it doesn't crash silently */
static int test_u16_div_by_zero(void) {
    const char *name = "u16 5000/0 ... should not hang/crash";
    uint16_t a = mk_u16(5000u);
    uint16_t b = mk_u16(0u);
    volatile uint16_t r = (uint16_t)(a / b);  /* volatile to force evaluation */
    /* If we reach here without crash ... ok (implementation-defined) */
    ok(name); return 1;  /* Adjust if you have a defined __div_by_zero handler */
}

/* Signed division rounding (C99+ toward zero) */
static int test_s16_div_toward_zero(void) {
    const char *name = "s16 -7/3 == -2 (toward zero)";
    int16_t a = mk_s16(-7);
    int16_t b = mk_s16(3);
    int16_t r = (int16_t)(a / b);
    if (r == -2) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_s32_div_toward_zero(void) {
    const char *name = "s32 -1000007/1000 == -1000 (toward zero)";
    int32_t a = mk_s32(-1000007L);
    int32_t b = mk_s32(1000L);
    int32_t r = a / b;
    if (r == -1000L) { ok(name); return 1; }
    fail(name); return 0;
}

/* Modulo sign follows dividend (C99) */
static int test_s16_mod_sign(void) {
    const char *name = "s16 -10 % 3 == -1";
    int16_t a = mk_s16(-10);
    int16_t b = mk_s16(3);
    int16_t r = (int16_t)(a % b);
    if (r == -1) { ok(name); return 1; }
    fail(name); return 0;
}



/* Signed overflow in multiplication (implementation-defined, but test consistency) */
static int test_s16_mul_overflow(void) {
    const char *name = "s16 30000 * 1000 overflow ... ? (impl defined)";
    int16_t a = mk_s16(30000);
    int16_t b = mk_s16(1000);
    volatile int16_t r = (int16_t)(a * b);  /* should wrap or trap */
    /* Just check it doesn't crash; compare to known impl if you want */
    ok(name); return 1;  /* or add expected value if you control runtime */
}

/* More widening mul tests (signed & larger values) */
static int test_s16x_s16_to_s32(void) {
    const char *name = "(s16)-30000 * (s16)2000 ... s32 -60000000";
    int16_t a = mk_s16(-30000);
    int16_t b = mk_s16(2000);
    int32_t r = (int32_t)a * (int32_t)b;
    if (r == -60000000L) { ok(name); return 1; }
    fail(name); return 0;
}

static int test_u16x_u16_large_to_u32(void) {
    const char *name = "(u16)65535 * (u16)65535 ... u32 4294836225";
    uint16_t a = mk_u16(65535u);
    uint16_t b = mk_u16(65535u);
    uint32_t r = (uint32_t)a * (uint32_t)b;
    if (r == 4294836225UL) { ok(name); return 1; }
    fail(name); return 0;
}

/* Signed right-shift on most-negative value (arithmetic shift preserves sign) */
static int test_s32_sar_minval(void) {
    const char *name = "s32 INT32_MIN >> 1 == INT32_MIN / 2 (sign extended)";
    int32_t min = mk_s32((int32_t)0x80000000UL);
    int32_t r = min >> 1;
    if (r == (int32_t)0xC0000000UL) { ok(name); return 1; }
    fail(name); return 0;
}

/* Unsigned 32-bit mul with high product bits (low 32 only) */
static int test_u32_mul_high(void) {
    const char *name = "u32 0xFFFFFFFF * 0xFFFFFFFF low32 == 1";
    uint32_t r = mk_u32(0xFFFFFFFFUL) * mk_u32(0xFFFFFFFFUL);
    if (r == 1UL) { ok(name); return 1; }
    fail(name); return 0;
}


/* 3) s8/s16 arithmetic right shift */
static int test_s8_arshift(void){
    const char *n1="s8 -2>>1==-1";
    const char *n2="s8 -128>>1==-64";
    int8_t a = mk_s8((int8_t)-2);
    int8_t b = mk_s8((int8_t)-128);
    int8_t r1 = (int8_t)(mk_s8(a) >> mk_u8(1u));
    int8_t r2 = (int8_t)(mk_s8(b) >> mk_u8(1u));
    int okall=1;
    if(r1==(int8_t)-1){ ok(n1); } else { fail(n1); okall=0; }
    if(r2==(int8_t)-64){ ok(n2); } else { fail(n2); okall=0; }
    return okall;
}

static int test_s16_arshift(void){
    const char *n1="s16 -2>>1==-1";
    const char *n2="s16 -32768>>1==-16384";
    int16_t a = mk_s16((int16_t)-2);
    int16_t b = mk_s16((int16_t)-32768);
    int16_t r1 = (int16_t)(mk_s16(a) >> mk_u16(1u));
    int16_t r2 = (int16_t)(mk_s16(b) >> mk_u16(1u));
    int okall=1;
    if(r1==(int16_t)-1){ ok(n1); } else { fail(n1); okall=0; }
    if(r2==(int16_t)-16384){ ok(n2); } else { fail(n2); okall=0; }
    return okall;
}

/* 4) u32 add/sub carry/borrow */
static int test_u32_add_carry1(void){
    const char *name="u32 0x0000FFFF+1==0x00010000";
    uint32_t a = mk_u32(0x0000FFFFUL);
    uint32_t r = mk_u32(a) + mk_u32(1UL);
    if(r==0x00010000UL){ ok(name); return 1; } fail(name); return 0;
}

static int test_u32_add_wrap(void){
    const char *name="u32 0xFFFFFFFF+1==0x00000000";
    uint32_t a = mk_u32(0xFFFFFFFFUL);
    uint32_t r = mk_u32(a) + mk_u32(1UL);
    if(r==0x00000000UL){ ok(name); return 1; } fail(name); return 0;
}

static int test_u32_sub_borrow1(void){
    const char *name="u32 0x00010000-1==0x0000FFFF";
    uint32_t a = mk_u32(0x00010000UL);
    uint32_t r = mk_u32(a) - mk_u32(1UL);
    if(r==0x0000FFFFUL){ ok(name); return 1; } fail(name); return 0;
}

static int test_u32_sub_wrap(void){
    const char *name="u32 0x00000000-1==0xFFFFFFFF";
    uint32_t a = mk_u32(0x00000000UL);
    uint32_t r = mk_u32(a) - mk_u32(1UL);
    if(r==0xFFFFFFFFUL){ ok(name); return 1; } fail(name); return 0;
}

/* 5) u32 multiply edges */
static int test_u32_mul_edge1(void){
    const char *name="u32 0xFFFFFFFF*2==0xFFFFFFFE";
    uint32_t a = mk_u32(0xFFFFFFFFUL);
    uint32_t r = mk_u32(a) * mk_u32(2UL);
    if(r==0xFFFFFFFEUL){ ok(name); return 1; } fail(name); return 0;
}

static int test_u32_mul_edge2(void){
    const char *name="u32 0x80000000*2==0x00000000";
    uint32_t a = mk_u32(0x80000000UL);
    uint32_t r = mk_u32(a) * mk_u32(2UL);
    if(r==0x00000000UL){ ok(name); return 1; } fail(name); return 0;
}

/* 6) u32 div/mod power-of-two */
static int test_u32_div_pow2(void){
    const char *name="u32 0x12345678/256==0x00123456";
    uint32_t a = mk_u32(0x12345678UL);
    uint32_t q = mk_u32(a) / mk_u32(256UL);
    if(q==0x00123456UL){ ok(name); return 1; } fail(name); return 0;
}

static int test_u32_mod_pow2(void){
    const char *name="u32 0x12345678%256==0x00000078";
    uint32_t a = mk_u32(0x12345678UL);
    uint32_t m = mk_u32(a) % mk_u32(256UL);
    if(m==0x00000078UL){ ok(name); return 1; } fail(name); return 0;
}

/* 7) s32 division/remainder sign rules */
static int test_s32_div_n7_p3(void){
    const char *name="s32 -7/3==-2";
    int32_t a = mk_s32(-7);
    int32_t b = mk_s32(3);
    int32_t q = mk_s32(a) / mk_s32(b);
    if(q==(int32_t)-2){ ok(name); return 1; } fail(name); return 0;
}

static int test_s32_mod_n7_p3(void){
    const char *name="s32 -7%3==-1";
    int32_t a = mk_s32(-7);
    int32_t b = mk_s32(3);
    int32_t m = mk_s32(a) % mk_s32(b);
    if(m==(int32_t)-1){ ok(name); return 1; } fail(name); return 0;
}

static int test_s32_div_p7_n3(void){
    const char *name="s32 7/-3==-2";
    int32_t a = mk_s32(7);
    int32_t b = mk_s32(-3);
    int32_t q = mk_s32(a) / mk_s32(b);
    if(q==(int32_t)-2){ ok(name); return 1; } fail(name); return 0;
}

static int test_s32_mod_p7_n3(void){
    const char *name="s32 7%-3==1";
    int32_t a = mk_s32(7);
    int32_t b = mk_s32(-3);
    int32_t m = mk_s32(a) % mk_s32(b);
    if(m==(int32_t)1){ ok(name); return 1; } fail(name); return 0;
}

/* 8) optional observe-only UB edge */
static int test_s32_min_div_minus1_observe(void){
    const char *name="s32 INT32_MIN/-1 (observe behavior)";
    int32_t a = mk_s32((int32_t)0x80000000L);
    int32_t b = mk_s32((int32_t)-1);
    int32_t q = mk_s32(a) / mk_s32(b);
    (void)q;
    ok(name);
    return 1;
}

/* 9) promotions / extensions */
static int test_u16_to_u32_zero_extend(void){
    const char *name="u32 (u16)0xFFFF -> 0x0000FFFF";
    uint16_t a = mk_u16(0xFFFFu);
    uint32_t r = mk_u32((uint32_t)a);
    if(r==0x0000FFFFUL){ ok(name); return 1; } fail(name); return 0;
}

static int test_s16_to_s32_sign_extend(void){
    const char *name="s32 (s16)-1 -> 0xFFFFFFFF";
    int16_t a = mk_s16((int16_t)-1);
    int32_t r = mk_s32((int32_t)a);
    if((uint32_t)r==0xFFFFFFFFUL){ ok(name); return 1; } fail(name); return 0;
}

static int test_u8_to_u32_zero_extend(void){
    const char *name="u32 (u8)0xFF -> 0x000000FF";
    uint8_t a = mk_u8(0xFFu);
    uint32_t r = mk_u32((uint32_t)a);
    if(r==0x000000FFUL){ ok(name); return 1; } fail(name); return 0;
}

static int test_s8_to_s32_sign_extend(void){
    const char *name="s32 (s8)-1 -> 0xFFFFFFFF";
    int8_t a = mk_s8((int8_t)-1);
    int32_t r = mk_s32((int32_t)a);
    if((uint32_t)r==0xFFFFFFFFUL){ ok(name); return 1; } fail(name); return 0;
}

/* 10) comparisons */
static int test_u32_cmp_gt0(void){
    const char *name="u32 0xFFFFFFFF>0";
    uint32_t a = mk_u32(0xFFFFFFFFUL);
    uint32_t b = mk_u32(0UL);
    if(mk_u32(a) > mk_u32(b)){ ok(name); return 1; } fail(name); return 0;
}

static int test_s32_cmp_neg_lt0(void){
    const char *name="s32 -1<0";
    int32_t a = mk_s32((int32_t)-1);
    int32_t b = mk_s32((int32_t)0);
    if(mk_s32(a) < mk_s32(b)){ ok(name); return 1; } fail(name); return 0;
}

/* 11) widening multiply promotion */
static int test_u16_mul_promote_u32(void){
    const char *name="u32 (u16)65535*(u16)65535==0xFFFE0001";
    uint16_t a = mk_u16(65535u);
    uint16_t b = mk_u16(65535u);
    uint32_t r = (uint32_t)mk_u32((uint32_t)a) * (uint32_t)mk_u32((uint32_t)b);
    if(r==0xFFFE0001UL){ ok(name); return 1; } fail(name); return 0;
}


static int test_u32_shr_31(void){
    const char *name="u32 0x80000000>>31 == 1";
    uint32_t x = mk_u32(0x80000000UL);
    uint32_t r = (uint32_t)(x >> mk_u32(31u));
    if (r == 1u) { ok(name); return 1; } fail(name); return 0;
}

static int test_s32_mod_large_neg(void) {
    const char *name = "s32 -2147483647 % 1000000 == -483647";
    int32_t a = mk_s32(-2147483647L);
    int32_t b = mk_s32(1000000L);
    int32_t r = mk_s32(a) % mk_s32(b);
    if (r == (int32_t)-483647L) { ok(name); return 1; }
    fail(name); return 0;
}


/* ---------- main ---------- */

void main(void){
    cinit();
    cclear();

    int passed=0, total=0;

    cputs("ZX int helper suite\n");

    total++; passed += test_u8_wrap_add();
    total++; passed += test_s8_cmp();
    total++; passed += test_u16_add();
    total++; passed += test_u16_sub();
    total++; passed += test_u16_mul();
    total++; passed += test_u16_div();
    total++; passed += test_u16_mod();
    total++; passed += test_s16_mul();
    total++; passed += test_s16_div();
    total++; passed += test_s16_mod();
    total++; passed += test_u16_shl();
    total++; passed += test_u16_shr();
    total++; passed += test_s16_sar();
    total++; passed += test_u16_cmp();
    total++; passed += test_s16_cmp();
    total++; passed += test_sext8_to_s16();
    total++; passed += test_zext8_to_u16();
    total++; passed += test_u16_u32_roundtrip();
    total++; passed += test_u8_shl();
    total++; passed += test_u8_shr();
    total++; passed += test_u16_inc_wrap();
    total++; passed += test_u16_dec_wrap();
    total++; passed += test_s16_neg();
    total++; passed += test_s32_cmp();
    total++; passed += test_u32_shifts();
    total++; passed += test_s32_sar();
    total++; passed += test_u32_add_carry();
    total++; passed += test_u32_sub_borrow();
    total++; passed += test_u8_bits();
    total++; passed += test_u16_bits();
    total++; passed += test_u16x_u16_to_u32();
    total++; passed += test_u32_mul();
    total++; passed += test_u32_bits();
    total++; passed += test_u32_divmod();
    total++; passed += test_s32_divmod();
    total++; passed += test_u16_div_by_zero();        
    total++; passed += test_s16_div_toward_zero();
    total++; passed += test_s32_div_toward_zero();
    total++; passed += test_s16_mod_sign();      
    total++; passed += test_s16_mul_overflow();        
    total++; passed += test_s16x_s16_to_s32();
    total++; passed += test_u16x_u16_large_to_u32();
    total++; passed += test_s32_sar_minval();
    total++; passed += test_u32_mul_high();
    total++; passed += test_u32_mul_wrap();
    total++; passed += test_s32_mul_neg();
    total++; passed += test_mixed_signed_unsigned_cmp();
    total++; passed += test_signed_plus_unsigned_arith();
    total++; passed += test_u16_compound_assign_wrap();
    total++; passed += test_s16_div_compound();
    total++; passed += test_bitwise_not_u32();
    total++; passed += test_u16_shift_large();
    total++; passed += test_s32_mod_negative_small();
    total++; passed += test_s8_arshift();
    total++; passed += test_s16_arshift();
    total++; passed += test_u32_add_carry1();
    total++; passed += test_u32_add_wrap();
    total++; passed += test_u32_sub_borrow1();
    total++; passed += test_u32_sub_wrap();
    total++; passed += test_u32_mul_edge1();
    total++; passed += test_u32_mul_edge2();
    total++; passed += test_u32_div_pow2();
    total++; passed += test_u32_mod_pow2();
    total++; passed += test_s32_div_n7_p3();
    total++; passed += test_s32_mod_n7_p3();
    total++; passed += test_s32_div_p7_n3();
    total++; passed += test_s32_mod_p7_n3();
    total++; passed += test_s32_min_div_minus1_observe();
    total++; passed += test_u16_to_u32_zero_extend();
    total++; passed += test_s16_to_s32_sign_extend();
    total++; passed += test_u8_to_u32_zero_extend();
    total++; passed += test_s8_to_s32_sign_extend();
    total++; passed += test_u32_cmp_gt0();
    total++; passed += test_s32_cmp_neg_lt0();
    total++; passed += test_u16_mul_promote_u32();
    total++; passed += test_u32_shr_31();
    total++; passed += test_s32_mod_large_neg(); 

    cputs("Summary: ");
    put_hex16((uint16_t)passed);
    cputc('/');
    put_hex16((uint16_t)total);
    cputs("\n");
}
