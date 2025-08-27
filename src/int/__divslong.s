        ;; signed 32-bit division with remainder helper (long)
        ;; divides x by y; __divslong returns quotient (de:hl),
        ;; while __get_remainder_long returns the remainder (de:hl) with
        ;; the correct sign (matching the dividend).
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module divlong                             ; module name
        .optsdcc -mz80 sdcccall(1)


        .area   _CODE                               ; code segment

        .globl  __divslong                          ; export symbols
        .globl  __get_remainder_long
        .globl  __modslong

        ;; frame layout used by these helpers (relative to ix):
        ;;   -10(ix) : sign flag of dividend (0 = +, 1 = -)
        ;;   -9..-6  : absolute divisor copy (low..high)
        ;;   -5..-2  : remainder (low..high)

        ;; __divslong
        ;; inputs (sdcccall(1)):
        ;;   de:hl = dividend x (signed 32-bit, de high, hl low)
        ;;   4(ix)..7(ix) = divisor y (signed 32-bit, little endian)
        ;; outputs:
        ;;   de:hl = quotient q (signed 32-bit, de high, hl low)
        ;; side effects:
        ;;   stores unsigned remainder to -5..-2(ix),
        ;;   stores dividend sign (0/1) to -10(ix) for __get_remainder_long
        ;; clobbers:
        ;;   a, b, c, d, e, h, l, f; preserves ix for the helper
__divslong:
        push    ix                                  ; set up frame
        ld      ix, #0
        add     ix, sp

        ;; reserve 10 bytes of locals
        ld      hl, #-10
        add     hl, sp
        ld      sp, hl

        ;; clear remainder (-5..-2) and sign flag (-10)
        xor     a
        ld      -5(ix), a
        ld      -4(ix), a
        ld      -3(ix), a
        ld      -2(ix), a
        ld      -10(ix), a

        ;; copy divisor y and take |y| into -9..-6 (low..high)
        ld      a, 4(ix)                            ; y0
        ld      -9(ix), a
        ld      a, 5(ix)                            ; y1
        ld      -8(ix), a
        ld      a, 6(ix)                            ; y2
        ld      -7(ix), a
        ld      a, 7(ix)                            ; y3 (sign byte)
        ld      -6(ix), a

        bit     7, -6(ix)                           ; if y < 0, negate local copy
        jr      z, .div_y_abs_done
        xor     a                                   ; a = 0
        sub     a, -9(ix)
        ld      -9(ix), a
        xor     a
        sbc     a, -8(ix)
        ld      -8(ix), a
        xor     a
        sbc     a, -7(ix)
        ld      -7(ix), a
        xor     a
        sbc     a, -6(ix)
        ld      -6(ix), a
.div_y_abs_done:

        ;; save sign(x) into -10(ix); if x < 0, make x = |x|
        bit     7, d
        jr      z, .div_x_abs_done
        ld      -10(ix), #1                         ; remember dividend was negative
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
.div_x_abs_done:

        ;; unsigned 32/32 divide:
        ;; quotient accumulates in de:hl (shift/sub), remainder in -5..-2(ix)
        ld      b, #32
.u32_div_loop:
        ;; shift quotient (x) left by 1 (low first so carry flows upwards)
        add     hl, hl
        rl      e
        rl      d

        ;; shift remainder left by 1, bringing in the carry bit from above
        rl      -2(ix)                              ; rem low0
        rl      -3(ix)                              ; rem low1
        rl      -4(ix)                              ; rem high0
        rl      -5(ix)                              ; rem high1

        ;; try: remainder -= |y|
        or      a                                   ; clear carry
        ld      a, -2(ix)
        sbc     a, -9(ix)
        ld      -2(ix), a
        ld      a, -3(ix)
        sbc     a, -8(ix)
        ld      -3(ix), a
        ld      a, -4(ix)
        sbc     a, -7(ix)
        ld      -4(ix), a
        ld      a, -5(ix)
        sbc     a, -6(ix)
        ld      -5(ix), a
        jr      nc, .keep_sub

        ;; borrow -> restore remainder (add |y| back)
        ld      a, -2(ix)
        adc     a, -9(ix)
        ld      -2(ix), a
        ld      a, -3(ix)
        adc     a, -8(ix)
        ld      -3(ix), a
        ld      a, -4(ix)
        adc     a, -7(ix)
        ld      -4(ix), a
        ld      a, -5(ix)
        adc     a, -6(ix)
        ld      -5(ix), a
        jr      .next_bit

.keep_sub:
        set     0, l                                ; set lsb of quotient
.next_bit:
        djnz    .u32_div_loop

        ;; set quotient sign: if (x<0)^(y<0) then negate de:hl
        ;; we have sign(x) in -10(ix), and sign(y) is bit7 of original 7(ix)
        ld      a, -10(ix)
        bit     7, 7(ix)
        jr      z, .no_flip
        xor     #1
.no_flip:
        or      a
        jr      z, .div_q_done

        ;; negate quotient
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
.div_q_done:
        ;; leave: de:hl = quotient, remainder in -5..-2(ix),
        ;;        -10(ix) holds (x<0) as 0/1
        ret                                          ; keep ix for helper

        ;; __get_remainder_long
        ;; inputs:  expects to be called in the *same frame* as __divslong
        ;;          (ix still valid), with remainder stored at -5..-2(ix)
        ;; outputs: de:hl = remainder (signed 32-bit, sign matches dividend)
        ;; clobbers: a, d, e, h, l, f; preserves ix
__get_remainder_long:
        ld      l, -2(ix)                           ; gather remainder into de:hl
        ld      h, -3(ix)
        ld      e, -4(ix)
        ld      d, -5(ix)

        ld      a, -10(ix)                          ; if original dividend < 0
        or      a
        ret     z                                    ; remainder already positive

        ;; negate remainder
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
        ret
