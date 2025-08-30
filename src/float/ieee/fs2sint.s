        ;; float -> signed int (ieee-754 single) for sdcc z80
        ;; converts 32-bit float to 16-bit signed int with truncation toward zero.
        ;; behavior:
        ;;   |x| < 1 -> 0
        ;;   x >=  32768 ->  32767
        ;;   x <= -32768 -> -32768
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2sint
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fs2sint
        ;; inputs:  (stack) float a
        ;; outputs: hl = (int)a
        ;; clobbers: af, bc, de, hl
        .globl  ___fs2sint
___fs2sint:
        ; pop return, fetch arg (low then high), restore ret
        pop     de              ; DE <- return address
        pop     hl              ; HL <- low word
        pop     bc              ; BC <- high word
        push    bc
        push    hl
        push    de

        ; sign?
        ld      a,b
        and     #0x80
        jr      z, .pos

        ; negative: compute magnitude using same path as unsigned, then negate with clamp
        ; exponent e
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
        jr      nc, .neg_e_nonneg
        xor     a
        ld      h,a
        ld      l,a
        ret
.neg_e_nonneg:
        cp      #15
        jr      c, .neg_within
        ; magnitude >= 2^15 -> clamp to -32768
        ld      hl,#0x8000
        ret
.neg_within:
        ; build mantissa D:B:C = 1.xxx (24-bit)
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      d,a
        ld      b,h
        ld      c,l
        ; shift as in fs2uint to get magnitude (unsigned) in HL
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
        ; negate: result = -HL  (truncate already done)
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        inc     hl
        ret
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
        ; negate
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        inc     hl
        ret

.pos:
        ; positive path == fs2uint with 16-bit clamp
        ; exponent e
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
        jr      nc, .pos_e_nonneg
        xor     a
        ld      h,a
        ld      l,a
        ret
.pos_e_nonneg:
        cp      #15
        jr      c, .pos_within
        ld      hl,#0x7FFF
        ret
.pos_within:
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      d,a
        ld      b,h
        ld      c,l
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
        ret
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
        ret
