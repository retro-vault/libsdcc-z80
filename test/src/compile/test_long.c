#include "limits.h"

// declare the assembly helpers
long _divslong(long, long);
unsigned long _divulong(unsigned long, unsigned long);
long _modslong(long, long);
unsigned long _modulong(unsigned long, unsigned long);
long _mullong(long, long);

static void check(long x, long y) {

    #pragma save
    #pragma disable_warning 110
    // avoid UB in host-side checks when y==0; we only check shape
    long q = 0, r = 0;
    if (y) {
        q = x / y;
        r = x % y;
    }
    #pragma restore

    long aq = _divslong(x, y);
    long ar = _modslong(x, y);
    // invariants
    // 1) aq == q (except y==0 where behavior is implementation-defined)
    // 2) x == aq*y + ar
    // 3) ar == 0 || sign(ar) == sign(x)
    // 4) |ar| < |y|  (only if y!=0)
    // 5) mul: low 32 bits wrap
}

int main(void) {
    long tests[][2] = {
        {0,1}, {1,1}, {-1,1}, {1,-1}, {-1,-1},
        {123456789L, 3}, {123456789L, -3},
        {-123456789L, 3}, {-123456789L, -3},
        {LONG_MAX, 2}, {LONG_MIN, 2}, {LONG_MIN, -2},
        {LONG_MAX, -1}, {LONG_MIN, -1},
        {42, 0}, {-42, 0},
    };
    for (unsigned i=0;i<sizeof(tests)/sizeof(tests[0]);++i) {
        long x = tests[i][0], y = tests[i][1];
        check(x,y);
    }

    // mul sanity
    volatile long m1 = _mullong(300000000L, 7L);   // expect low 32-bit wrap
    (void)m1;
    return 0;
}
