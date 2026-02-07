        ;; float -> unsigned int (ieee-754 single) for sdcc z80
        ;; converts 32-bit float to 16-bit unsigned int with truncation toward zero.
        ;; behavior:
        ;;   negative -> 0
        ;;   too small (|x| < 1) -> 0
        ;;   too large (x >= 65536) -> 65535
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2uint
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fs2uint
        ;; inputs:  float a in hl:de (observed from mk_f32 call chain)
        ;; outputs: de = (unsigned int)a  (caller does ex de,hl)
        ;; clobbers: af, bc, de, hl
        .globl  ___fs2uint
___fs2uint:
        ;; mk_f32 returns hl:de (hl=high, de=low). swap to get:
        ;;   hl = low word, de = high word
        ex      de,hl

        ;; BC = high word, HL = low word
        ld      b,d
        ld      c,e

        ;; negative -> 0
        ld      a,b
        and     #0x80
        jr      z, .positive
        xor     a
        ld      h,a
        ld      l,a
        ld      d,h
        ld      e,l
        ret

.positive:
        ;; exponent field exp = ((B & 0x7F) << 1) | (C >> 7)
        ld      a,b
        and     #0x7F
        rla
        ld      e,a
        ld      a,c
        and     #0x80
        jr      z, .exp_done
        inc     e
.exp_done:
        ;; unbiased e = exp - 127
        ld      a,e
        sub     #127
        ld      e,a

        ;; if e < 0 -> 0
        jr      nc, .e_nonneg
        xor     a
        ld      h,a
        ld      l,a
        ld      d,h
        ld      e,l
        ret

.e_nonneg:
        ;; if e >= 16 -> clamp to 0xFFFF
        ld      a,e
        cp      #16
        jr      c, .within
        ld      hl,#0xFFFF
        ld      d,h
        ld      e,l
        ret

.within:
        ;; build mantissa D:B:C = 1.xxx (24-bit)
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      d,a
        ld      b,h
        ld      c,l

        ;; right shift by (23 - e), where e is 0..15 here
        ld      a,#23
        sub     e

.rsh_loop:
        srl     d
        rr      b
        rr      c
        dec     a
        jr      nz, .rsh_loop

        ;; result = B:C
        ld      h,b
        ld      l,c
        ld      d,h
        ld      e,l
        ret
