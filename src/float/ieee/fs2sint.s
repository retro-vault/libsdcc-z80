        ;; float -> signed int (ieee-754 single) for sdcc z80
        ;; converts 32-bit float to 16-bit signed int with truncation toward zero.
        ;;
        ;; behavior:
        ;;   |x| < 1        -> 0
        ;;   x >=  32768    ->  32767
        ;;   x <= -32768    -> -32768
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2sint
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fs2sint
        ;; inputs:  float a in hl:de (sdcccall(1), observed)
        ;; outputs: de = (int)a      (caller does ex de,hl)
        ;; clobbers: af, bc, de, hl
        .globl  ___fs2sint
___fs2sint:
        ;; swap so:
        ;;   BC = high word
        ;;   HL = low word
        ex      de,hl
        ld      b,d
        ld      c,e

        ;; sign?
        ld      a,b
        and     #0x80
        jp      z, .pos

        ;; ----------------------------
        ;; negative
        ;; ----------------------------

        ;; extract exponent
        ld      a,b
        and     #0x7F
        rla
        ld      e,a
        ld      a,c
        and     #0x80
        jr      z, .neg_e_low
        inc     e
.neg_e_low:
        ld      a,e
        sub     #127
        ld      e,a                 ;; unbiased exponent

        jr      nc, .neg_e_nonneg

        ;; |x| < 1 -> 0
        xor     a
        ld      h,a
        ld      l,a
        ld      d,h
        ld      e,l
        ret

.neg_e_nonneg:
        ld      a,e
        cp      #15
        jr      c, .neg_within

        ;; clamp to -32768
        ld      hl,#0x8000
        ld      d,h
        ld      e,l
        ret

.neg_within:
        ;; build mantissa D:B:C = 1.xxx (24-bit)
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      d,a
        ld      b,h
        ld      c,l

        ;; shift magnitude
        ld      a,e
        cp      #24
        jr      c, .neg_sr
        sub     #23

.neg_sl_loop:
        sla     c
        rl      b
        rl      d
        dec     a
        jr      nz, .neg_sl_loop
        ld      h,d
        ld      l,b
        jr      .neg_apply

.neg_sr:
        ld      a,#23
        sub     e
.neg_rsh_loop:
        srl     d
        rr      b
        rr      c
        dec     a
        jr      nz, .neg_rsh_loop
        ld      h,b
        ld      l,c

.neg_apply:
        ;; negate HL
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        inc     hl

        ld      d,h
        ld      e,l
        ret

        ;; ----------------------------
        ;; positive
        ;; ----------------------------

.pos:
        ;; extract exponent
        ld      a,b
        and     #0x7F
        rla
        ld      e,a
        ld      a,c
        and     #0x80
        jr      z, .pos_e_low
        inc     e
.pos_e_low:
        ld      a,e
        sub     #127
        ld      e,a                 ;; unbiased exponent

        jr      nc, .pos_e_nonneg

        ;; |x| < 1 -> 0
        xor     a
        ld      h,a
        ld      l,a
        ld      d,h
        ld      e,l
        ret

.pos_e_nonneg:
        ld      a,e
        cp      #15
        jr      c, .pos_within

        ;; clamp to +32767
        ld      hl,#0x7FFF
        ld      d,h
        ld      e,l
        ret

.pos_within:
        ;; build mantissa D:B:C = 1.xxx
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      d,a
        ld      b,h
        ld      c,l

        ;; shift magnitude
        ld      a,e
        cp      #24
        jr      c, .pos_sr
        sub     #23

.pos_sl_loop:
        sla     c
        rl      b
        rl      d
        dec     a
        jr      nz, .pos_sl_loop
        ld      h,d
        ld      l,b
        jr      .pos_done

.pos_sr:
        ld      a,#23
        sub     e
.pos_rsh_loop:
        srl     d
        rr      b
        rr      c
        dec     a
        jr      nz, .pos_rsh_loop
        ld      h,b
        ld      l,c

.pos_done:
        ld      d,h
        ld      e,l
        ret
