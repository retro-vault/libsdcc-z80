        ;; unsigned 32-bit modulus (long)
        ;;
        ;; implemented by reusing __divulong and its stored remainder.
        ;;
        ;; ABI (sdcccall(1), matches your build):
        ;;   x (dividend) in regs:  DE = low16, HL = high16
        ;;   y (divisor)  on stack: 4(ix)..7(ix) = y0..y3 (lsb..msb)
        ;; returns:
        ;;   remainder in regs:     DE = low16, HL = high16
        ;;

        .module modulong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  __modulong
        .globl  __divulong
        .globl  __get_remainder_ulong

__modulong:
        ;; __divulong expects divisor bytes at 4(ix)..7(ix) relative to
        ;; its own frame. Preserve that by tail-jumping with a synthetic
        ;; return address directly above the original divisor bytes.
        pop     bc
        ld      a, c
        ld      (__modulong_ret+0), a
        ld      a, b
        ld      (__modulong_ret+1), a

        ld      bc, #.after_div
        push    bc
        jp      __divulong

.after_div:
        ld      a, (__modulong_ret+0)
        ld      c, a
        ld      a, (__modulong_ret+1)
        ld      b, a
        push    bc
        jp      __get_remainder_ulong

        .area   _DATA
__modulong_ret:
        .ds     2
