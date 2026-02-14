        ;;
        ;; signed 32-bit division (long)
        ;;
        ;; ABI (sdcccall(1), matches your build):
        ;;   x (dividend) in regs:  DE = low16, HL = high16
        ;;   y (divisor)  on stack: 4(ix)..7(ix) = y0..y3 (lsb..msb)
        ;; returns:
        ;;   quotient in regs:      DE = low16, HL = high16
        ;;
        ;; semantics:
        ;;   q = trunc(x / y) toward zero
        ;;

        .module divlong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  __divslong
        .globl  __get_remainder_slong

        ;; locals (relative to ix):
        ;;   -1      : sign_q (0/1) = sign(x) xor sign(y)
        ;;   -2      : sign_x (0/1) = sign(x)
        ;;   -6..-3  : abs(y) (low..high)
        ;;   -10..-7 : remainder (low..high)

__divslong:
        push    ix
        ld      ix, #0
        add     ix, sp

        ;; save incoming x.high (HL) into BC; HL used for frame math
        ld      b, h
        ld      c, l

        ;; reserve 10 bytes locals
        ld      hl, #-10
        add     hl, sp
        ld      sp, hl

        ;; restore HL (x.high)
        ld      h, b
        ld      l, c

        ;; clear sign flags
        xor     a
        ld      -1(ix), a
        ld      -2(ix), a

        ;; normalize x into internal order DE:HL = high:low
        ;; incoming: DE low, HL high -> internal: DE high, HL low
        ex      de, hl

        ;; determine sign(x), store to -2(ix), and abs(x) if negative
        bit     7, d
        jr      z, .x_abs_done
        ld      -2(ix), #1
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

        ;; copy y from stack 4..7 into abs(y) locals -6..-3 (low..high)
        ld      a, 4(ix)
        ld      -6(ix), a
        ld      a, 5(ix)
        ld      -5(ix), a
        ld      a, 6(ix)
        ld      -4(ix), a
        ld      a, 7(ix)
        ld      -3(ix), a

        ;; compute sign_q = sign(x) xor sign(y)
        ld      a, -2(ix)
        bit     7, -3(ix)
        jr      z, .sign_q_done
        xor     #1
.sign_q_done:
        ld      -1(ix), a

        ;; abs(y) if negative
        bit     7, -3(ix)
        jr      z, .y_abs_done
        xor     a
        sub     a, -6(ix)
        ld      -6(ix), a
        ld      a, #0
        sbc     a, -5(ix)
        ld      -5(ix), a
        ld      a, #0
        sbc     a, -4(ix)
        ld      -4(ix), a
        ld      a, #0
        sbc     a, -3(ix)
        ld      -3(ix), a
.y_abs_done:

        ;; remainder = 0 at -10..-7 (low..high)
        xor     a
        ld      -10(ix), a
        ld      -9(ix),  a
        ld      -8(ix),  a
        ld      -7(ix),  a

        ;; fast path: |x| == 0 => q=0, r=0
        ld      a, d
        or      e
        or      h
        or      l
        jr      nz, .chk_abs_y_is_1
        jp      .post_div

        ;; fast path: |y| == 1 => q=|x|, r=0
.chk_abs_y_is_1:
        ld      a, -6(ix)
        cp      #1
        jr      nz, .chk_pow2_byte_aligned
        ld      a, -5(ix)
        or      a
        jr      nz, .chk_pow2_byte_aligned
        ld      a, -4(ix)
        or      a
        jr      nz, .chk_pow2_byte_aligned
        ld      a, -3(ix)
        or      a
        jr      nz, .chk_pow2_byte_aligned
        jp      .post_div

        ;; fast path: byte-aligned powers of two on abs(y)
        ;; abs(y) == 0x00000100, 0x00010000, 0x01000000
.chk_pow2_byte_aligned:
        ld      a, -6(ix)
        or      a
        jr      nz, .chk_x_lt_y

        ;; abs(y) == 0x00000100 ?
        ld      a, -5(ix)
        cp      #1
        jr      nz, .chk_pow2_16
        ld      a, -4(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ld      a, -3(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ;; q = abs(x) >> 8 ; r = abs(x) & 0xFF
        ld      -10(ix), l
        xor     a
        ld      -9(ix), a
        ld      -8(ix), a
        ld      -7(ix), a
        ld      l, h
        ld      h, e
        ld      e, d
        ld      d, a
        jp      .post_div

.chk_pow2_16:
        ;; abs(y) == 0x00010000 ?
        ld      a, -5(ix)
        or      a
        jr      nz, .chk_pow2_24
        ld      a, -4(ix)
        cp      #1
        jr      nz, .chk_x_lt_y
        ld      a, -3(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ;; q = abs(x) >> 16 ; r = abs(x) & 0xFFFF
        ld      -10(ix), l
        ld      -9(ix), h
        xor     a
        ld      -8(ix), a
        ld      -7(ix), a
        ld      l, e
        ld      h, d
        ld      e, a
        ld      d, a
        jp      .post_div

.chk_pow2_24:
        ;; abs(y) == 0x01000000 ?
        ld      a, -5(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ld      a, -4(ix)
        or      a
        jr      nz, .chk_x_lt_y
        ld      a, -3(ix)
        cp      #1
        jr      nz, .chk_x_lt_y
        ;; q = abs(x) >> 24 ; r = abs(x) & 0xFFFFFF
        ld      -10(ix), l
        ld      -9(ix), h
        ld      -8(ix), e
        xor     a
        ld      -7(ix), a
        ld      l, d
        ld      h, a
        ld      e, a
        ld      d, a
        jp      .post_div

        ;; fast path: |x| < |y| => q=0, r=|x|
.chk_x_lt_y:
        ld      a, d
        cp      -3(ix)
        jr      c, .x_lt_y
        jr      nz, .run_div
        ld      a, e
        cp      -4(ix)
        jr      c, .x_lt_y
        jr      nz, .run_div
        ld      a, h
        cp      -5(ix)
        jr      c, .x_lt_y
        jr      nz, .run_div
        ld      a, l
        cp      -6(ix)
        jr      c, .x_lt_y
        jr      .run_div

.x_lt_y:
        ld      -10(ix), l
        ld      -9(ix), h
        ld      -8(ix), e
        ld      -7(ix), d
        xor     a
        ld      d, a
        ld      e, a
        ld      h, a
        ld      l, a
        jr      .post_div

        ;; unsigned restoring division: quotient in de:hl, remainder in locals
.run_div:
        ;; unsigned restoring division: quotient in de:hl, remainder in locals
        ld      b, #32

.u32_div_loop:
        ;; shift quotient (x) left by 1
        add     hl, hl
        rl      e
        rl      d

        ;; remainder <<= 1, bring in carry from x shift
        rl      -10(ix)
        rl      -9(ix)
        rl      -8(ix)
        rl      -7(ix)

        ;; try: remainder -= abs(y)
        or      a                                   ; clear carry
        ld      a, -10(ix)
        sbc     a, -6(ix)
        ld      -10(ix), a
        ld      a, -9(ix)
        sbc     a, -5(ix)
        ld      -9(ix), a
        ld      a, -8(ix)
        sbc     a, -4(ix)
        ld      -8(ix), a
        ld      a, -7(ix)
        sbc     a, -3(ix)
        ld      -7(ix), a
        jr      nc, .keep_sub

        ;; borrow -> restore remainder (add abs(y) back)
        or      a                                   ; CLEAR carry before adc!
        ld      a, -10(ix)
        adc     a, -6(ix)
        ld      -10(ix), a
        ld      a, -9(ix)
        adc     a, -5(ix)
        ld      -9(ix), a
        ld      a, -8(ix)
        adc     a, -4(ix)
        ld      -8(ix), a
        ld      a, -7(ix)
        adc     a, -3(ix)
        ld      -7(ix), a
        jr      .next_bit

.keep_sub:
        set     0, l

.next_bit:
        djnz    .u32_div_loop

.post_div:
        ;; normalize remainder sign to original dividend sign and store
        ;; for __modslong helper path.
        ld      a, -2(ix)
        or      a
        jr      z, .store_remainder

        xor     a
        sub     a, -10(ix)
        ld      -10(ix), a
        ld      a, #0
        sbc     a, -9(ix)
        ld      -9(ix), a
        ld      a, #0
        sbc     a, -8(ix)
        ld      -8(ix), a
        ld      a, #0
        sbc     a, -7(ix)
        ld      -7(ix), a

.store_remainder:
        ld      a, -10(ix)
        ld      (__last_remainder_slong+0), a
        ld      a, -9(ix)
        ld      (__last_remainder_slong+1), a
        ld      a, -8(ix)
        ld      (__last_remainder_slong+2), a
        ld      a, -7(ix)
        ld      (__last_remainder_slong+3), a

        ;; apply quotient sign if needed (sign_q in -1(ix))
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
        ;; quotient currently internal (DE high, HL low) -> ABI wants (DE low, HL high)
        ex      de, hl

        ;; tear down frame
        ld      sp, ix
        pop     ix
        ret

__get_remainder_slong:
        ;; returns last remainder as DE low, HL high
        ld      hl, #__last_remainder_slong
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
__last_remainder_slong:
        .ds     4
