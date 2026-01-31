        ;;
        ;; signed 32-bit modulus (long), reentrant
        ;;
        ;; ABI (sdcccall(1), matches your build):
        ;;   x (dividend) in regs:  DE = low16, HL = high16
        ;;   y (divisor)  on stack: 4(ix)..7(ix) = y0..y3 (lsb..msb)
        ;; returns:
        ;;   remainder in regs:     DE = low16, HL = high16
        ;;
        ;; semantics:
        ;;   r has the same sign as x (dividend)
        ;;

        .module modlong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  __modslong

        ;; locals (relative to ix):
        ;;   -1      : sign_x (0/1)
        ;;   -5..-2  : abs(y) (low..high)
        ;;   -9..-6  : remainder (low..high)

__modslong:
        push    ix
        ld      ix, #0
        add     ix, sp

        ;; save incoming x.high (HL) into BC; HL used for frame math
        ld      b, h
        ld      c, l

        ;; reserve 9 bytes locals
        ld      hl, #-9
        add     hl, sp
        ld      sp, hl

        ;; restore HL (x.high)
        ld      h, b
        ld      l, c

        ;; sign_x = 0
        xor     a
        ld      -1(ix), a

        ;; normalize x into internal order DE:HL = high:low
        ex      de, hl

        ;; if x < 0: sign_x=1 and abs(x)
        bit     7, d
        jr      z, .x_abs_done
        ld      -1(ix), #1
        xor     a
        sub     a, l
        ld      l, a
        ld      a, #0
        sbc     a, h
        ld      h, a
        ld      a, #0
        sbc     a, e
        ld      e, a
        ld      a, #0
        sbc     a, d
        ld      d, a
.x_abs_done:

        ;; copy y from stack into abs(y) locals -5..-2 (low..high)
        ld      a, 4(ix)
        ld      -5(ix), a
        ld      a, 5(ix)
        ld      -4(ix), a
        ld      a, 6(ix)
        ld      -3(ix), a
        ld      a, 7(ix)
        ld      -2(ix), a

        ;; abs(y) if negative
        bit     7, -2(ix)
        jr      z, .y_abs_done
        xor     a
        sub     a, -5(ix)
        ld      -5(ix), a
        ld      a, #0
        sbc     a, -4(ix)
        ld      -4(ix), a
        ld      a, #0
        sbc     a, -3(ix)
        ld      -3(ix), a
        ld      a, #0
        sbc     a, -2(ix)
        ld      -2(ix), a
.y_abs_done:

        ;; remainder = 0 at -9..-6 (low..high)
        xor     a
        ld      -9(ix), a
        ld      -8(ix), a
        ld      -7(ix), a
        ld      -6(ix), a

        ;; unsigned restoring division core (quotient ignored, remainder kept)
        ld      b, #32

.u32_mod_loop:
        add     hl, hl
        rl      e
        rl      d

        rl      -9(ix)
        rl      -8(ix)
        rl      -7(ix)
        rl      -6(ix)

        or      a                                   ; clear carry
        ld      a, -9(ix)
        sbc     a, -5(ix)
        ld      -9(ix), a
        ld      a, -8(ix)
        sbc     a, -4(ix)
        ld      -8(ix), a
        ld      a, -7(ix)
        sbc     a, -3(ix)
        ld      -7(ix), a
        ld      a, -6(ix)
        sbc     a, -2(ix)
        ld      -6(ix), a
        jr      nc, .keep_sub

        ;; restore remainder
        or      a                                   ; CLEAR carry before adc!
        ld      a, -9(ix)
        adc     a, -5(ix)
        ld      -9(ix), a
        ld      a, -8(ix)
        adc     a, -4(ix)
        ld      -8(ix), a
        ld      a, -7(ix)
        adc     a, -3(ix)
        ld      -7(ix), a
        ld      a, -6(ix)
        adc     a, -2(ix)
        ld      -6(ix), a
        jr      .next_bit

.keep_sub:
        set     0, l                                ; quotient bit (ignored)

.next_bit:
        djnz    .u32_mod_loop

        ;; load remainder into regs (internal order: bytes low..high)
        ld      l, -9(ix)
        ld      h, -8(ix)
        ld      e, -7(ix)
        ld      d, -6(ix)

        ;; if original x was negative, negate remainder
        ld      a, -1(ix)
        or      a
        jr      z, .ret_order

        xor     a
        sub     a, l
        ld      l, a
        ld      a, #0
        sbc     a, h
        ld      h, a
        ld      a, #0
        sbc     a, e
        ld      e, a
        ld      a, #0
        sbc     a, d
        ld      d, a

.ret_order:
        ;; remainder currently internal (DE high, HL low) -> ABI wants (DE low, HL high)
        ex      de, hl

        ld      sp, ix
        pop     ix
        ret
