        ;;
        ;; unsigned 32-bit division (long)
        ;;
        ;; ABI (sdcccall(1), matches your build):
        ;;   dividend x in regs:  DE = low16, HL = high16
        ;;   divisor  y on stack: 4(ix)..7(ix) = y0..y3 (lsb..msb)
        ;; returns:
        ;;   quotient in DE = low16, HL = high16
        ;;
        ;; remainder is saved to a static cell for optional retrieval.
        ;;

        .module divulong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  __divulong
        .globl  __get_remainder_ulong

        ;; locals (relative to ix):
        ;;   -8..-5  : remainder (low..high)
        ;;   -12..-9 : divisor y (low..high)

__divulong:
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

        ;; normalize dividend into internal order DE:HL = high:low
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

        ;; fast path: x == 0 => q=0, r=0
        ld      a, d
        or      e
        or      h
        or      l
        jr      nz, .chk_div1
        jp      .store_remainder

        ;; fast path: y == 1 => q=x, r=0
.chk_div1:
        ld      a, -12(ix)
        cp      #1
        jr      nz, .chk_pow2_byte_aligned
        ld      a, -11(ix)
        or      a
        jr      nz, .chk_pow2_byte_aligned
        ld      a, -10(ix)
        or      a
        jr      nz, .chk_pow2_byte_aligned
        ld      a, -9(ix)
        or      a
        jr      nz, .chk_pow2_byte_aligned
        jp      .store_remainder

        ;; fast path: byte-aligned powers of two
        ;; y == 0x00000100, 0x00010000, 0x01000000
.chk_pow2_byte_aligned:
        ld      a, -12(ix)
        or      a
        jr      nz, .chk_x_lt_y

        ;; y == 0x00000100 ?
        ld      a, -11(ix)
        cp      #1
        jr      nz, .chk_pow2_16
        ld      a, -10(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ld      a, -9(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ;; q = x >> 8 ; r = x & 0xFF
        ld      -8(ix), l
        xor     a
        ld      -7(ix), a
        ld      -6(ix), a
        ld      -5(ix), a
        ld      l, h
        ld      h, e
        ld      e, d
        ld      d, a
        jp      .store_remainder

.chk_pow2_16:
        ;; y == 0x00010000 ?
        ld      a, -11(ix)
        or      a
        jr      nz, .chk_pow2_24
        ld      a, -10(ix)
        cp      #1
        jr      nz, .chk_x_lt_y
        ld      a, -9(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ;; q = x >> 16 ; r = x & 0xFFFF
        ld      -8(ix), l
        ld      -7(ix), h
        xor     a
        ld      -6(ix), a
        ld      -5(ix), a
        ld      l, e
        ld      h, d
        ld      e, a
        ld      d, a
        jp      .store_remainder

.chk_pow2_24:
        ;; y == 0x01000000 ?
        ld      a, -11(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ld      a, -10(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ld      a, -9(ix)
        cp      #1
        jr      nz, .chk_x_lt_y
        ;; q = x >> 24 ; r = x & 0xFFFFFF
        ld      -8(ix), l
        ld      -7(ix), h
        ld      -6(ix), e
        xor     a
        ld      -5(ix), a
        ld      l, d
        ld      h, a
        ld      e, a
        ld      d, a
        jp      .store_remainder

        ;; fast path: x < y => q=0, r=x
.chk_x_lt_y:
        ld      a, d
        cp      -9(ix)
        jr      c, .x_lt_y
        jr      nz, .run_div
        ld      a, e
        cp      -10(ix)
        jr      c, .x_lt_y
        jr      nz, .run_div
        ld      a, h
        cp      -11(ix)
        jr      c, .x_lt_y
        jr      nz, .run_div
        ld      a, l
        cp      -12(ix)
        jr      c, .x_lt_y
        jr      .run_div

.x_lt_y:
        ld      -8(ix), l
        ld      -7(ix), h
        ld      -6(ix), e
        ld      -5(ix), d
        xor     a
        ld      d, a
        ld      e, a
        ld      h, a
        ld      l, a
        jr      .store_remainder

        ;; 32 iterations, restoring division
.run_div:
        ;; 32 iterations, restoring division
        ld      b, #32

.u32_div_loop:
        ;; shift quotient (currently in de:hl) left by 1
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
        set     0, l

.next_bit:
        djnz    .u32_div_loop

.store_remainder:
        ;; store remainder to static cell
        ld      a, -8(ix)
        ld      (__last_remainder_ulong+0), a
        ld      a, -7(ix)
        ld      (__last_remainder_ulong+1), a
        ld      a, -6(ix)
        ld      (__last_remainder_ulong+2), a
        ld      a, -5(ix)
        ld      (__last_remainder_ulong+3), a

        ;; quotient currently internal (DE high, HL low) -> ABI wants (DE low, HL high)
        ex      de, hl

        ;; tear down frame
        ld      sp, ix
        pop     ix
        ret


__get_remainder_ulong:
        ;; returns last remainder from static cell as DE low, HL high
        ld      hl, #__last_remainder_ulong
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        ret


        .area   _DATA
__last_remainder_ulong:
        .ds     4
