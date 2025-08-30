/* fp_abi_smoke.c
   Exercise SDCC's Z80 float helper set so the linker demands them all.
   No libm, no %f — only core ops & conversions.

   Build (example):
     sdcc -mz80 --std-sdcc99 --opt-code-speed fp_abi_smoke.c

   Expect: undefined symbols like ___fsadd, ___fsmul, ___fsdiv, ___fscmp,
           ___sint2fs, ___fs2sint, ___uint2fs, ___fs2uint, ___slong2fs, ___fs2slong, etc.
*/

/* "static assert" style checks that don't need C11 */
typedef char check_float_is_32bit[ (sizeof(float)  == 4) ? 1 : -1 ];

/* Use volatile to block constant-folding so helpers are actually referenced. */
static volatile float   vf0 = 1.25f, vf1 = -2.5f, vf2 = 0.0f;
static volatile int     vi0 = 123,   vi1 = -456;
static volatile unsigned int vui0 = 40000u;
static volatile long    vl0 = 123456L, vl1 = -234567L;
static volatile unsigned long vul0 = 345678UL;

static float ret_f(float x) { return x; }                 /* return path */

static void sink_f(float x);   /* prevent optimizing away */
static void sink_f(float x) { (void)x; }

static void sink_i(int x);     /* ditto */
static void sink_i(int x) { (void)x; }

static void sink_u(unsigned x);
static void sink_u(unsigned x) { (void)x; }

static void sink_l(long x);
static void sink_l(long x) { (void)x; }

static void sink_ul(unsigned long x);
static void sink_ul(unsigned long x) { (void)x; }

/* Arithmetic ops (+, -, *, /) */
void test_arith(void) {
    float a = vf0;
    float b = vf1;
    float c;

    c = a + b; sink_f(c);      /* ___fsadd */
    c = a - b; sink_f(c);      /* ___fssub */
    c = a * b; sink_f(c);      /* ___fsmul */
    c = a / (b + 3.0f); sink_f(c);  /* ___fsdiv (+ add) */

    /* unary + and - */
    c = +a;  sink_f(c);
    c = -b;  sink_f(c);
}

/* Comparisons: == != < <= > >= — forces ___fscmp (or wrappers) */
void test_cmp(void) {
    float a = vf0, b = vf1;
    int r = 0;

    r += (a == b);
    r += (a != b);
    r += (a <  b);
    r += (a <= b);
    r += (a >  b);
    r += (a >= b);
    sink_i(r);
}

/* Conversions float -> {schar, uchar, int, uint, long, ulong} */
void test_to_ints(void) {
    float a = vf0;

    /* char/uchar go through int promotions but still require helpers in SDCC builds */
    signed char  sc = (signed char)a;  sink_i(sc);   /* ___fs2schar (or via ___fs2sint) */
    unsigned char uc = (unsigned char)a; sink_u(uc); /* ___fs2uchar (or via ___fs2uint) */

    int     si = (int)a;               sink_i(si);   /* ___fs2sint  */
    unsigned ui = (unsigned)a;         sink_u(ui);   /* ___fs2uint  */
    long    sl = (long)a;              sink_l(sl);   /* ___fs2slong */
    unsigned long ul = (unsigned long)a; sink_ul(ul);/* ___fs2ulong */
}

/* Conversions {schar, uchar, int, uint, long, ulong} -> float */
void test_from_ints(void) {
    signed char  sc  = (signed char)vi1;
    unsigned char uc = (unsigned char)vui0;

    float f;

    f = (float)sc;     sink_f(f); /* ___schar2fs (or via ___sint2fs) */
    f = (float)uc;     sink_f(f); /* ___uchar2fs (or via ___uint2fs) */
    f = (float)vi0;    sink_f(f); /* ___sint2fs  */
    f = (float)vui0;   sink_f(f); /* ___uint2fs  */
    f = (float)vl0;    sink_f(f); /* ___slong2fs */
    f = (float)vul0;   sink_f(f); /* ___ulong2fs */
}

/* Mixed int<->float arithmetic forces implicit conversions + ops */
void test_mixed(void) {
    float a = vf0;
    int   i = vi0;
    unsigned u = vui0;
    long  l = vl0;
    unsigned long ul = vul0;

    float f;

    f = a + i;  sink_f(f);    /* int->float + add */
    f = a - u;  sink_f(f);    /* uint->float + sub */
    f = a * l;  sink_f(f);    /* long->float + mul */
    f = a / (ul + 1UL); sink_f(f); /* ulong->float + div */
}

/* Return/arg passing in functions (keeps ABI consistent, may force helpers) */
float add_ret(float x, float y) { return x + y; } /* ___fsadd */
float mul_ret(float x, float y) { return x * y; } /* ___fsmul */

void test_calls(void) {
    float a = vf0, b = vf1;
    sink_f(add_ret(a, b));
    sink_f(mul_ret(a, b));
    sink_f(ret_f(a));
}

/* Force division-by-non-const to ensure real call is emitted */
void test_div_runtime(void) {
    float a = vf0, b = vf1;
    volatile float z = b + vf2; /* keep non-const */
    sink_f(a / (z + 1.0f));     /* ___fsdiv */
}

int main(void) {
    test_arith();
    test_cmp();
    test_to_ints();
    test_from_ints();
    test_mixed();
    test_calls();
    test_div_runtime();

    /* Also touch zeros/negatives to tick sign paths */
    float s = -vf0 + (+vf2);
    sink_f(s);

    return 0;
}
