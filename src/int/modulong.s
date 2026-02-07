        ;;
        ;; unsigned 32-bit modulus (long), reentrant/thread-safe
        ;;
        ;; ABI (sdcccall(1), matches your build):
        ;;   x (dividend) in regs:  DE = low16, HL = high16
        ;;   y (divisor)  on stack: 4(ix)..7(ix) = y0..y3 (lsb..msb)
        ;; returns:
        ;;   remainder in regs:     DE = low16, HL = high16
        ;;
        ;; algorithm: restoring division; quotient bits are formed in the
        ;; shifted dividend register but are ignored; remainder is kept
        ;; in frame locals and returned.
        ;;

        .module modulong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  __modulong

        ;; locals (relative to ix):
        ;;   -8..-5  : remainder (low..high)
        ;;   -12..-9 : divisor y (low..high)

__modulong:
        push    ix
        ld      ix, #0
        add     ix, sp

        ;; save incoming x.high (HL) into BC; HL needed for frame math
        ld      b, h
        ld      c, l

        ;; reserve 12 bytes locals
        ld      hl, #-12
        add     hl, sp
        ld      sp, hl

        ;; restore HL (x.high)
        ld      h, b
        ld      l, c

        ;; normalize x into internal order DE:HL = high:low
        ;; incoming: DE low, HL high -> internal: DE high, HL low
        ex      de, hl

        ;; remainder = 0
        xor     a
        ld      -8(ix), a
        ld      -7(ix), a
        ld      -6(ix), a
        ld      -5(ix), a

        ;; copy divisor y into -12..-9 from 4..7(ix) (low..high)
        ld      a, 4(ix)
        ld      -12(ix), a
        ld      a, 5(ix)
        ld      -11(ix), a
        ld      a, 6(ix)
        ld      -10(ix), a
        ld      a, 7(ix)
        ld      -9(ix), a

        ;; 32 iterations
        ld      b, #32

.u32_mod_loop:
        ;; shift dividend (quotient accumulator) left by 1
        add     hl, hl
        rl      e
        rl      d

        ;; remainder <<= 1, bring in carry from dividend shift
        rl      -8(ix)
        rl      -7(ix)
        rl      -6(ix)
        rl      -5(ix)

        ;; try remainder -= divisor
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

        ;; borrow -> restore remainder (add divisor back)
        or      a                                  ; CLEAR carry before adc!
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
        set     0, l                               ; quotient bit (ignored)

.next_bit:
        djnz    .u32_mod_loop

        ;; return remainder:
        ;; locals are low..high bytes:
        ;;   -8 = byte0, -7 = byte1, -6 = byte2, -5 = byte3
        ;; ABI wants DE=low16, HL=high16
        ld      e, -8(ix)
        ld      d, -7(ix)
        ld      l, -6(ix)
        ld      h, -5(ix)

        ;; tear down frame
        ld      sp, ix
        pop     ix
        ret
