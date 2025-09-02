// gpl-2.0-or-later (see: LICENSE)
// (c) 2025 tomaz stih

#include <stdint.h>

/* ROM I/O */
extern void cinit(void);
extern void cclear(void);
extern void cputs(const char *s);
extern void cputc(char ch);

/* ---------- tiny print helpers (no stdlib, no division) ---------- */

static char hex_digit(uint8_t n) { n &= 0xF; return (n < 10) ? ('0'+n) : ('A'+(n-10)); }

static void put_hex8(uint8_t v) {
    char b[3];
    b[0] = hex_digit(v>>4); b[1] = hex_digit(v); b[2] = 0;
    cputs(b);
}
static void put_hex16(uint16_t v) {
    char b[5];
    b[0]=hex_digit(v>>12); b[1]=hex_digit(v>>8); b[2]=hex_digit(v>>4); b[3]=hex_digit(v); b[4]=0;
    cputs(b);
}
static void put_hex32(uint32_t v) {
    char b[9];
    b[0]=hex_digit((uint8_t)(v>>28)); b[1]=hex_digit(v>>24); b[2]=hex_digit(v>>20); b[3]=hex_digit(v>>16);
    b[4]=hex_digit(v>>12); b[5]=hex_digit(v>>8); b[6]=hex_digit(v>>4); b[7]=hex_digit(v); b[8]=0;
    cputs(b);
}

/* status lines */
static void ok(const char *name){ cputs("ok  "); cputs(name); cputs("\n"); }
static void fail(const char *name){ cputs("FAIL "); cputs(name); cputs("\n"); }

/* ---------- tests ------------------------------------------------- */

/* u8 / s8 */
static int test_u8_wrap_add(void){
    const char *name="u8 add wrap 250+10==4";
    uint8_t a=250u, b=10u, r=(uint8_t)(a+b);
    if(r==4u){ ok(name); return 1; } fail(name); return 0;
}
static int test_s8_neg_cmp(void){
    const char *name="<s8> -5 < 3";
    int8_t a=-5, b=3;
    if(a<b){ ok(name); return 1; } fail(name); return 0;
}

/* u16 / s16 core arithmetic */
static int test_u16_add(void){
    const char *name="add 1234+4321==5555";
    uint16_t r=(uint16_t)(1234u+4321u);
    if(r==5555u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_sub(void){
    const char *name="sub 7000-1234==5766";
    uint16_t r=(uint16_t)(7000u-1234u);
    if(r==5766u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_mul(void){
    const char *name="mul 123*45==5535";
    uint16_t r=(uint16_t)(123u*45u);
    if(r==5535u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_div(void){
    const char *name="div 5000/125==40";
    uint16_t r=(uint16_t)(5000u/125u);
    if(r==40u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_mod(void){
    const char *name="mod 5010%125==10";
    uint16_t r=(uint16_t)(5010u%125u);
    if(r==10u){ ok(name); return 1; } fail(name); return 0;
}
static int test_s16_mul(void){
    const char *name="mul -123*45==-5535";
    int16_t r=(int16_t)((int16_t)-123*45);
    if(r==(int16_t)-5535){ ok(name); return 1; } fail(name); return 0;
}
static int test_s16_div(void){
    const char *name="div -30000/1000==-30";
    int16_t r=(int16_t)((int16_t)-30000/1000);
    if(r==(int16_t)-30){ ok(name); return 1; } fail(name); return 0;
}
static int test_s16_mod(void){
    const char *name="mod -30000%1000==0";
    int16_t r=(int16_t)((int16_t)-30000%1000);
    if(r==0){ ok(name); return 1; } fail(name); return 0;
}

/* shifts */
static int test_u16_shl(void){
    const char *name="shl 0x1234<<3==0x91A0";
    uint16_t r=(uint16_t)(0x1234u<<3);
    if(r==0x91A0u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_shr(void){
    const char *name="shr 0x8001>>3==0x1000";
    uint16_t r=(uint16_t)(0x8001u>>3);
    if(r==0x1000u){ ok(name); return 1; } fail(name); return 0;
}
static int test_s16_sar(void){
    const char *name="sar 0x8000>>1==0xC000";
    int16_t r=(int16_t)((int16_t)0x8000>>1);
    if((uint16_t)r==0xC000u){ ok(name); return 1; } fail(name); return 0;
}

/* comparisons */
static int test_u16_cmp(void){
    const char *n1="cmp 1000<2000 (u16)";
    const char *n2="cmp 3000==3000 (u16)";
    int okall=1;
    if(1000u<2000u) ok(n1); else { fail(n1); okall=0; }
    if(3000u==3000u) ok(n2); else { fail(n2); okall=0; }
    return okall;
}
static int test_s16_cmp(void){
    const char *n1="cmp -2<1 (s16)";
    const char *n2="cmp -2!=-1 (s16)";
    int okall=1;
    if(((int16_t)-2)<((int16_t)1)) ok(n1); else { fail(n1); okall=0; }
    if(((int16_t)-2)!=((int16_t)-1)) ok(n2); else { fail(n2); okall=0; }
    return okall;
}

/* u32 / s32 (exercise long helpers) */
static int test_u32_mul(void){
    const char *name="u32 mul 70000*3==210000";
    uint32_t r=(uint32_t)70000uL*3u;
    if(r==210000uL){ ok(name); return 1; } fail(name); return 0;
}
static int test_u32_divmod(void){
    const char *name1="u32 div 1000000/3==333333";
    const char *name2="u32 mod 1000000%3==1";
    uint32_t a=1000000uL;
    uint32_t q=a/3u;
    uint32_t m=a%3u;
    int okall=1;
    if(q==333333uL) ok(name1); else { fail(name1); okall=0; }
    if(m==1u) ok(name2); else { fail(name2); okall=0; }
    return okall;
}
static int test_s32_divmod(void){
    const char *name1="s32 div -1000000/3==-333333";
    const char *name2="s32 mod -1000000%3==-1";
    int okall=1;
    int32_t q=((int32_t)-1000000)/3;
    int32_t m=((int32_t)-1000000)%3;
    if(q==(int32_t)-333333) ok(name1); else { fail(name1); okall=0; }
    if(m==(int32_t)-1) ok(name2); else { fail(name2); okall=0; }
    return okall;
}
static int test_u32_shifts(void){
    const char *n1="u32 shl 12345678<<4==23456780";
    const char *n2="u32 shr 12345678>>4==01234567";
    uint32_t x=0x12345678UL;
    int okall=1;
    if( (x<<4) == 0x23456780UL ) ok(n1); else { fail(n1); okall=0; }
    if( (x>>4) == 0x01234567UL ) ok(n2); else { fail(n2); okall=0; }
    return okall;
}
static int test_s32_cmp(void){
    const char *n1="s32 cmp -5<2";
    const char *n2="u32 cmp 4e9>3e9";
    int okall=1;
    if( ((int32_t)-5) < ((int32_t)2) ) ok(n1); else { fail(n1); okall=0; }
    if( 4000000000uL > 3000000000uL ) ok(n2); else { fail(n2); okall=0; }
    return okall;
}

/* conversions / extensions */
static int test_sext8_to_s16(void){
    const char *name="sext (int8)0x80 -> 0xFF80";
    int16_t r=(int16_t)(int8_t)0x80;
    if((uint16_t)r==0xFF80u){ ok(name); return 1; } fail(name); return 0;
}
static int test_zext8_to_u16(void){
    const char *name="zext (uint8)0x80 -> 0x0080";
    uint16_t r=(uint16_t)(uint8_t)0x80;
    if(r==0x0080u){ ok(name); return 1; } fail(name); return 0;
}
static int test_u16_u32_roundtrip(void){
    const char *name="u16->u32->u16 65535";
    uint16_t u=65535u; uint32_t w=(uint32_t)u; uint16_t u2=(uint16_t)w;
    if(u2==u){ ok(name); return 1; } fail(name); return 0;
}

/* ---------- main -------------------------------------------------- */

void main(void){
    cinit();
    cclear();

    int passed=0, total=0;

    cputs("ZX int helper suite\n");

    total++; passed += test_u8_wrap_add();
    total++; passed += test_s8_neg_cmp();

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

    total++; passed += test_u32_mul();
    total++; passed += test_u32_divmod();
    total++; passed += test_s32_divmod();
    total++; passed += test_u32_shifts();
    total++; passed += test_s32_cmp();

    total++; passed += test_sext8_to_s16();
    total++; passed += test_zext8_to_u16();
    total++; passed += test_u16_u32_roundtrip();

    cputs("Summary: ");
    /* print "passed/total" in hex to avoid pulling decimal division */
    put_hex16((uint16_t)passed);
    cputc('/');
    put_hex16((uint16_t)total);
    cputs("\n");
}
