/* int_test.c — exercise SDCC integer helpers on Z80
   Build with your crt0 and link your libsdcc-z80.lib.
   Int is 16-bit, long is 32-bit on SDCC/Z80.
*/
typedef unsigned char  u8;
typedef signed   char  s8;
typedef unsigned int   u16;
typedef signed   int   s16;
typedef unsigned long  u32;
typedef signed   long  s32;

/* declare memmove so we don’t pull std headers */
void *memmove(void *dst, const void *src, unsigned int n);

volatile u8  sink_u8;
volatile s8  sink_s8;
volatile u16 sink_u16;
volatile s16 sink_s16;
volatile u32 sink_u32;
volatile s32 sink_s32;

static u8  vu8(void){ static volatile u8  x=0x5A; return x; }
static s8  vs8(void){ static volatile s8  x=-37;  return x; }
static u16 vu16(void){ static volatile u16 x=0xBEEF; return x; }
static s16 vs16(void){ static volatile s16 x=-1234;  return x; }
static u32 vu32(void){ static volatile u32 x=0x89ABCDEFUL; return x; }
static s32 vs32(void){ static volatile s32 x=-2147480000L; return x; }

/* prevent inlining/const-folding */
#pragma disable_warning 85

static void test_u8_s8(void){
    u8 a = vu8(), b = 13;
    s8 c = vs8(), d = -7;
    sink_u8  = a+b; sink_u8  ^= a-b; sink_u8  ^= a*b;
    sink_u8  ^= (u8)(a/ (u8)3);      /* __divuchar */
    sink_u8  ^= (u8)(a% (u8)5);      /* __moduchar */
    sink_s8  = c+d; sink_s8  ^= c-d; sink_s8  ^= c*d;
    sink_s8  ^= (s8)(c/ (s8)-3);     /* __divchar */
    sink_s8  ^= (s8)(c% (s8)5);      /* __modchar */
    sink_u8  ^= (u8)(c);             /* sign->uns widen */
    sink_s8  ^= (s8)(a);             /* uns->sign cast */
    sink_u8  ^= (u8)(a << (b&7));    /* var shift */
    sink_u8  ^= (u8)(a >> (b&7));
    sink_s8  ^= (s8)(c << (d&7));
    sink_s8  ^= (s8)(c >> (d&7));    /* arithmetic shift */
}

static void test_u16_s16(void){
    u16 a = vu16(), b = 321;
    s16 c = vs16(), d = -37;
    sink_u16 = a+b; sink_u16 ^= a-b; sink_u16 ^= a*b;           /* muluint */
    sink_u16 ^= (u16)(a/(u16)7);                                 /* divuint */
    sink_u16 ^= (u16)(a%(u16)11);                                /* moduint */
    sink_s16 = c+d; sink_s16 ^= c-d; sink_s16 ^= c*d;           /* mulsint */
    sink_s16 ^= (s16)(c/(s16)-7);                                /* divsint */
    sink_s16 ^= (s16)(c%(s16)11);                                /* modsint */
    /* mixed signed/unsigned paths */
    sink_s16 ^= (s16)(c/(u16)13);                                /* divmixed */
    sink_s16 ^= (s16)((s16)(a)/(s16)-9);                         /* divsigned via cast */
    sink_u16 ^= (u16)((u16)(c)/(u16)9);                          /* divunsigned via cast */
    /* shifts */
    sink_u16 ^= (u16)(a << (b&15));
    sink_u16 ^= (u16)(a >> (b&15));
    sink_s16 ^= (s16)(c << (d&15));
    sink_s16 ^= (s16)(c >> (d&15));
}

static void test_u32_s32(void){
    u32 a = vu32(), b = 100003U;
    s32 c = vs32(), d = -30011L;
    sink_u32 = a+b; sink_u32 ^= a-b; sink_u32 ^= a*b;           /* mulul */
    sink_u32 ^= (u32)(a/(u32)7);                                 /* divul */
    sink_u32 ^= (u32)(a%(u32)13);                                /* modul */
    sink_s32 = c+d; sink_s32 ^= c-d; sink_s32 ^= c*d;           /* mull */
    sink_s32 ^= (s32)(c/(s32)-9);                                /* divl */
    sink_s32 ^= (s32)(c%(s32)11);                                /* modl */
    /* mixed */
    sink_s32 ^= (s32)(c/(u32)17);
    /* shifts */
    sink_u32 ^= (u32)(a << (b&31));
    sink_u32 ^= (u32)(a >> (b&31));
    sink_s32 ^= (s32)(c << (d&31));
    sink_s32 ^= (s32)(c >> (d&31));
    /* casts hit mul/div wideners */
    sink_u32 ^= (u32)( (u16)(a) * (u16)3 );
    sink_s32 ^= (s32)( (s16)(c) * (s16)-5 );
}

void main(void){
    test_u8_s8();
    test_u16_s16();
    test_u32_s32();
    /* hang so crt0 can return here */
    for(;;){}
}
