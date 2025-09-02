// gpl-2.0-or-later (see: LICENSE)
// (c) 2025 tomaz stih

#include <stdint.h>

/* ROM I/O */
extern void cinit(void);
extern void cclear(void);
extern void cputs(const char *s);
extern void cputc(char ch);

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
    const char *name="u8 (0xAA&0x0F)^(0xF0|0x01)==0x54";
    uint8_t r = (uint8_t)((mk_u8(0xAA)&mk_u8(0x0F)) ^ (mk_u8(0xF0)|mk_u8(0x01)));
    if (r == (uint8_t)0x54) { ok(name); return 1; } fail(name); return 0;
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
    const char *name="u16 (0x1234&0x0F0F)|(0x00F0^0x0FF0)==0x1FFF";
    uint16_t r = (uint16_t)((mk_u16(0x1234)&mk_u16(0x0F0F)) | (mk_u16(0x00F0)^mk_u16(0x0FF0)));
    if (r == 0x1FFFu) { ok(name); return 1; } fail(name); return 0;
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
static int test_u32_bits(void){
    const char *name="u32 (12345678&00FF00FF)^(0000FFFF|FF000000)==EDFF56E7";
    uint32_t r = (mk_u32(0x12345678UL)&mk_u32(0x00FF00FFUL)) ^
                 (mk_u32(0x0000FFFFUL)|mk_u32(0xFF000000UL));
    if (r == 0xEDFF56E7UL) { ok(name); return 1; } fail(name); return 0;
}
static int test_s32_sar(void){
    const char *name="s32 0x80000000>>1==0xC0000000";
    int32_t  x = mk_s32((int32_t)0x80000000UL);
    int32_t  r = (int32_t)(x >> mk_u32(1));
    if ((uint32_t)r == 0xC0000000UL) { ok(name); return 1; } fail(name); return 0;
}
/* widening mult: force 32-bit result by promoting operands first */
static int test_u16x_u16_to_u32(void){
    const char *name="(u16)60000*(u16)1000 -> u32 60000000";
    uint16_t a = mk_u16(60000u);
    uint16_t b = mk_u16(1000u);
    uint32_t r = (uint32_t)mk_u32((uint32_t)a) * (uint32_t)mk_u32((uint32_t)b);
    if (r == 60000000UL) { ok(name); return 1; } fail(name); return 0;
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

/*
    total++; passed += test_u8_bits();
    total++; passed += test_u32_mul();
    total++; passed += test_u16_bits();
    total++; passed += test_u16x_u16_to_u32();

    total++; passed += test_u32_bits();
    total++; passed += test_u32_divmod();
    total++; passed += test_s32_divmod();





*/
    cputs("Summary: ");
    put_hex16((uint16_t)passed);
    cputc('/');
    put_hex16((uint16_t)total);
    cputs("\n");
}
