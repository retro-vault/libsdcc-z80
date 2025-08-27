        ;; signed 32-bit multiply (low 32 bits)
        ;; computes (a * b) modulo 2^32, with sign from a^b
        ;; shift-add using unsigned core, then sign-fix
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module mullong                            ; module name
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE                              ; code segment

        .globl  __mullong                          ; export symbol

        ;; frame layout:
        ;;   -12..-9 : multiplier (copy of b, low..high)
        ;;   -8..-5  : accumulator/product low 32 bits
        ;;   -13     : sign flag (0/1) = sign(a) xor sign(b)
        ;;
        ;; __mullong
        ;; inputs:  de:hl = a (signed 32-bit, de high, hl low)
        ;;          4(ix)..7(ix) = b (signed 32-bit, little endian)
        ;; outputs: de:hl = (a*b) mod 2^32 (signed 32-bit per c semantics)
        ;; clobbers: a, b, c, d, e, h, l, f; preserves ix
__mullong:
        push    ix                                 ; establish frame
        ld      ix, #0
        add     ix, sp

        ;; reserve 13 bytes locals
        ld      hl, #-13
        add     hl, sp
        ld      sp, hl

        ;; compute sign = sign(a) xor sign(b) into -13(ix)
        xor     a
        ld      -13(ix), a
        bit     7, d
        jr      z, .a_nonneg
        ld      -13(ix), #1
.a_nonneg:
        bit     7, 7(ix)
        jr      z, .sign_done
        ld      a, -13(ix)
        xor     #1
        ld      -13(ix), a
.sign_done:

        ;; take abs(a) in de:hl if negative
        bit     7, d
        jr      z, .abs_a_done
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
.abs_a_done:

        ;; copy |b| into -12..-9 (and abs if negative)
        ld      a, 4(ix)
        ld      -12(ix), a
        ld      a, 5(ix)
        ld      -11(ix), a
        ld      a, 6(ix)
        ld      -10(ix), a
        ld      a, 7(ix)
        ld      -9(ix), a
        bit     7, -9(ix)
        jr      z, .abs_b_done
        xor     a
        sub     a, -12(ix)
        ld      -12(ix), a
        xor     a
        sbc     a, -11(ix)
        ld      -11(ix), a
        xor     a
        sbc     a, -10(ix)
        ld      -10(ix), a
        xor     a
        sbc     a, -9(ix)
        ld      -9(ix), a
.abs_b_done:

        ;; product accumulator = 0 at -8..-5
        xor     a
        ld      -8(ix), a
        ld      -7(ix), a
        ld      -6(ix), a
        ld      -5(ix), a

        ;; unsigned 32x32 -> low 32 via shift-add (lsb-first)
        ld      b, #32
.mul_loop:
        bit     0, -12(ix)                         ; if (multiplier & 1)
        jr      z, .no_add
        ;; acc += multiplicand (de:hl)
        ld      a, -8(ix)
        add     a, l
        ld      -8(ix), a
        ld      a, -7(ix)
        adc     a, h
        ld      -7(ix), a
        ld      a, -6(ix)
        adc     a, e
        ld      -6(ix), a
        ld      a, -5(ix)
        adc     a, d
        ld      -5(ix), a
.no_add:
        ;; multiplicand <<= 1
        add     hl, hl
        rl      e
        rl      d
        ;; multiplier >>= 1
        srl     -9(ix)
        rr      -10(ix)
        rr      -11(ix)
        rr      -12(ix)
        djnz    .mul_loop

        ;; move acc to de:hl
        ld      l, -8(ix)
        ld      h, -7(ix)
        ld      e, -6(ix)
        ld      d, -5(ix)

        ;; apply sign if needed
        ld      a, -13(ix)
        or      a
        jr      z, .done
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
.done:
        ld      sp, ix
        pop     ix
        ret
