        ;; unsigned 32-bit division (quotient + stored remainder)
        ;; computes q = x / y (unsigned); returns q, keeps r in frame locals
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module divulong                           ; module name
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE                              ; code segment

        .globl  __divulong                         ; export symbols
        .globl  __get_remainder_ulong

        ;; frame layout (relative to ix)
        ;;   -8..-5 : remainder (low..high, unsigned)
        ;;   -12..-9: |divisor y| (low..high)
        ;;
        ;; __divulong
        ;; inputs:  de:hl = x (unsigned 32-bit, de high, hl low)
        ;;          4(ix)..7(ix) = y (unsigned 32-bit, little endian)
        ;; outputs: de:hl = quotient (unsigned 32-bit)
        ;; side fx: stores remainder to -8..-5(ix)
        ;; clobbers: a, b, c, d, e, h, l, f; preserves ix for helper
__divulong:
        push    ix                                 ; establish frame
        ld      ix, #0
        add     ix, sp

        ;; reserve 12 bytes of locals
        ld      hl, #-12
        add     hl, sp
        ld      sp, hl

        ;; remainder = 0
        xor     a
        ld      -8(ix), a
        ld      -7(ix), a
        ld      -6(ix), a
        ld      -5(ix), a

        ;; copy divisor y into -12..-9
        ld      a, 4(ix)
        ld      -12(ix), a
        ld      a, 5(ix)
        ld      -11(ix), a
        ld      a, 6(ix)
        ld      -10(ix), a
        ld      a, 7(ix)
        ld      -9(ix), a

        ;; unsigned 32/32 division via shift/subtract
        ld      b, #32

.u32_div_loop:
        add     hl, hl                             ; x <<= 1 (low first)
        rl      e
        rl      d

        ;; remainder <<= 1, bring in carry from x shift
        rl      -8(ix)
        rl      -7(ix)
        rl      -6(ix)
        rl      -5(ix)

        ;; try remainder -= y
        or      a                                  ; clear carry
        ld      a, -8(ix)
        sbc     a, -12(ix)
        ld      -8(ix), a
        ld      a, -7(ix)
        sbc     a, -11(ix)
        ld      -7(ix), a
        ld      a, -6(ix)
        sbc     a, -10(ix)
        ld      -6(ix), a
        ld      a, -5(ix)
        sbc     a, -9(ix)
        ld      -5(ix), a
        jr      nc, .keep_sub

        ;; restore if we borrowed
        ld      a, -8(ix)
        adc     a, -12(ix)
        ld      -8(ix), a
        ld      a, -7(ix)
        adc     a, -11(ix)
        ld      -7(ix), a
        ld      a, -6(ix)
        adc     a, -10(ix)
        ld      -6(ix), a
        ld      a, -5(ix)
        adc     a, -9(ix)
        ld      -5(ix), a
        jr      .next_bit

.keep_sub:
        set     0, l                               ; quotient |= 1
.next_bit:
        djnz    .u32_div_loop

        ;; done: de:hl = quotient, remainder stored at -8..-5
        ret                                        ; leave ix for helper

        ;; __get_remainder_ulong
        ;; inputs:  same frame as __divulong (ix valid)
        ;; outputs: de:hl = remainder (unsigned 32-bit)
        ;; clobbers: d, e, h, l
__get_remainder_ulong:
        ld      l, -8(ix)
        ld      h, -7(ix)
        ld      e, -6(ix)
        ld      d, -5(ix)
        ret
