        ;; signed 32-bit modulus
        ;; computes r = a % b with sign(r) = sign(a) using unsigned core
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 your project

        .module modslong                           ; module name
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE                              ; code segment

        .globl  __modslong                         ; export symbol

        ;; __modslong
        ;; inputs:  de:hl = dividend (signed 32-bit, de high, hl low)
        ;;          4(ix)..7(ix) = divisor (signed 32-bit, little endian)
        ;; outputs: de:hl = remainder (signed 32-bit, same sign as dividend)
        ;; clobbers: a, b, c, d, e, h, l, ix, f
__modslong:
        push    ix
        ld      ix, #0
        add     ix, sp

        ;; locals: -8..-5 = |divisor|, -4..-1 = remainder
        ld      hl, #-8
        add     hl, sp
        ld      sp, hl

        ;; copy divisor to locals (-8..-5)
        ld      a, 4(ix)                           ; low0
        ld      -8(ix), a
        ld      a, 5(ix)                           ; low1
        ld      -7(ix), a
        ld      a, 6(ix)                           ; high0
        ld      -6(ix), a
        ld      a, 7(ix)                           ; high1
        ld      -5(ix), a

        ;; clear remainder (-4..-1)
        xor     a
        ld      -4(ix), a
        ld      -3(ix), a
        ld      -2(ix), a
        ld      -1(ix), a

        ;; remember dividend sign in c bit0; b=0 helper
        ld      bc, #0
        bit     7, d
        jr      z, .div_abs
        ;; negate dividend: de:hl = -de:hl
        xor     a
        sub     a, l
        ld      l, a
        xor     a
        sbc     a, h
        ld      h, a
        xor     a
        sbc     a, e
        ld      e, a
        xor     a
        sbc     a, d
        ld      d, a
        inc     c                                   ; mark negative dividend
.div_abs:
        ;; take abs(divisor) in locals if negative
        bit     7, -5(ix)
        jr      z, .abs_done
        xor     a
        sub     a, -8(ix)
        ld      -8(ix), a
        xor     a
        sbc     a, -7(ix)
        ld      -7(ix), a
        xor     a
        sbc     a, -6(ix)
        ld      -6(ix), a
        xor     a
        sbc     a, -5(ix)
        ld      -5(ix), a
.abs_done:
        ;; unsigned remainder via 32-step shift/subtract
        ld      b, #32
.u32_loop:
        add     hl, hl                             ; shift dividend left
        rl      e
        rl      d

        rl      -1(ix)                             ; remainder <<= 1
        rl      -2(ix)
        rl      -3(ix)
        rl      -4(ix)

        or      a                                  ; clear carry
        ld      a, -1(ix)                          ; rem -= divisor
        sbc     a, -8(ix)
        ld      -1(ix), a
        ld      a, -2(ix)
        sbc     a, -7(ix)
        ld      -2(ix), a
        ld      a, -3(ix)
        sbc     a, -6(ix)
        ld      -3(ix), a
        ld      a, -4(ix)
        sbc     a, -5(ix)
        ld      -4(ix), a
        jr      nc, .keep_sub

        ld      a, -1(ix)                          ; restore if borrowed
        adc     a, -8(ix)
        ld      -1(ix), a
        ld      a, -2(ix)
        adc     a, -7(ix)
        ld      -2(ix), a
        ld      a, -3(ix)
        adc     a, -6(ix)
        ld      -3(ix), a
        ld      a, -4(ix)
        adc     a, -5(ix)
        ld      -4(ix), a
.keep_sub:
        djnz    .u32_loop

        ;; fix sign: if original dividend negative, remainder := -remainder
        bit     0, c
        jr      z, .done
        xor     a
        sub     a, -1(ix)
        ld      -1(ix), a
        xor     a
        sbc     a, -2(ix)
        ld      -2(ix), a
        xor     a
        sbc     a, -3(ix)
        ld      -3(ix), a
        xor     a
        sbc     a, -4(ix)
        ld      -4(ix), a
.done:
        ;; move to de:hl and return
        ld      l, -1(ix)
        ld      h, -2(ix)
        ld      e, -3(ix)
        ld      d, -4(ix)

        ld      sp, ix
        pop     ix
        ret
