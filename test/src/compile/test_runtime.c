/* compile-only runtime helper coverage for sdcc z80
   this test is not executed; it exists to force link-time resolution
   of runtime/platform helper symbols using C constructs only. */

typedef unsigned char u8;
typedef unsigned int u16;

typedef u8 (*fn_u8_u8_t)(u8);

static volatile u8 sink_u8;

static u8 add1(u8 x) { return (u8)(x + 1); }
static volatile fn_u8_u8_t vf = add1;

/* Function pointer call (indirect call helper path). */
static u8 call_via_fp(u8 x) {
    fn_u8_u8_t f = vf;
    u8 y = f(x);
    sink_u8 ^= y;
    return (u8)(y + 3);
}

/* __critical construct (critical-section helper/sequence path). */
static void use_critical(void) {
    __critical {
        sink_u8 ^= call_via_fp(7);
    }
}

/* Banked call construct: with --model-large this should use bcall path. */
u8 banked_add2(u8 x) __banked;
u8 banked_add2(u8 x) __banked {
    return (u8)(x + 2);
}

static void use_banked_call(void) {
    sink_u8 ^= banked_add2(5);
}

/* Several local-heavy functions increase chance of shared ix prologue helper
   emission on size-oriented builds. */
static u8 local_heavy1(u8 a, u8 b) {
    u16 t = (u16)a + (u16)b;
    u8 k = (u8)(t ^ 0x5au);
    sink_u8 ^= k;
    return (u8)(k + a);
}

static u8 local_heavy2(u8 a) {
    u8 x0 = (u8)(a + 1);
    u8 x1 = (u8)(a + 3);
    u8 x2 = (u8)(a + 7);
    u8 x3 = (u8)(a + 15);
    u8 r = (u8)(x0 ^ x1 ^ x2 ^ x3);
    sink_u8 ^= r;
    return r;
}

void main(void) {
    use_critical();
    use_banked_call();
    sink_u8 ^= local_heavy1(3, 4);
    sink_u8 ^= local_heavy2(9);
    for (;;) {}
}
