        ;; float -> signed long (ieee-754 single) for sdcc z80
        ;; converts 32-bit float to 32-bit signed int with truncation toward zero.
        ;; behavior:
        ;;   |x| < 1              -> 0
        ;;   x >=  2^31           ->  0x7FFFFFFF (clamp)
        ;;   x <= -2^31           ->  0x80000000 (clamp)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2slong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fs2slong
        ;; inputs:  float a in hl:de (observed mk_f32 chain)
        ;; outputs: hl:de = (long)a   (sdcc expected)
        ;; clobbers: af, bc, de, hl
        .globl  ___fs2slong
___fs2slong:
        ;; arrange: HL = low word, DE = high word
        ex      de,hl                   ;; HL = low, DE = high

        ;; sign flag in B (0x80 or 0)
        ld      a,d
        and     #0x80
        ld      b,a

        ;; exp = ((D & 0x7F) << 1) | (E >> 7)
        ld      a,d
        and     #0x7F
        rla
        ld      c,a
        ld      a,e
        and     #0x80
        jr      z, .exp_done
        inc     c
.exp_done:
        ;; unbiased e = exp - 127
        ld      a,c
        sub     #127
        ld      c,a                     ;; C = unbiased e

        ;; if e < 0 -> 0
        jr      nc, .e_nonneg
        xor     a
        ld      d,a
        ld      e,a
        ld      h,a
        ld      l,a
        jp      .ret32

.e_nonneg:
        ;; clamp if e >= 31
        ld      a,c
        cp      #31
        jr      c, .build_mag

        bit     7,b
        jr      z, .clamp_pos
        ld      d,#0x80
        ld      e,#0x00
        ld      h,#0x00
        ld      l,#0x00
        jr      .ret32
.clamp_pos:
        ld      d,#0x7F
        ld      e,#0xFF
        ld      h,#0xFF
        ld      l,#0xFF
        jr      .ret32

.build_mag:
        ;; build magnitude into DE:HL as 32-bit unsigned from mantissa
        ;; DE:HL = 0 : M2 : M1 : M0
        ;; M2 = (E & 0x7F) | 0x80
        ;; M1:M0 = low word = HL currently
        ld      a,e
        and     #0x7F
        or      #0x80
        ld      e,a
        ld      d,#0x00

        ;; shift based on e (C) relative to 23
        ld      a,c
        cp      #23
        jr      z, .apply_sign
        jr      c, .shift_right

        ;; left shift by (e - 23)
        sub     #23
.lsh_loop:
        sla     l
        rl      h
        rl      e
        rl      d
        dec     a
        jr      nz, .lsh_loop
        jr      .apply_sign

.shift_right:
        ;; right shift by (23 - e)
        ld      a,#23
        sub     c
.rsh_loop:
        srl     d
        rr      e
        rr      h
        rr      l
        dec     a
        jr      nz, .rsh_loop

.apply_sign:
        ;; DE:HL is magnitude
        bit     7,b
        jr      z, .pos_path

        ;; negative: clamp if magnitude > 0x80000000
        ld      a,d
        cp      #0x80
        jr      c, .neg_twos
        jr      nz, .neg_clamp
        ld      a,e
        or      h
        or      l
        jr      z, .ret32                ;; exactly 0x80000000
.neg_clamp:
        ld      d,#0x80
        ld      e,#0x00
        ld      h,#0x00
        ld      l,#0x00
        jr      .ret32

.neg_twos:
        ;; two's complement negate DE:HL
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        ld      a,e
        cpl
        ld      e,a
        ld      a,d
        cpl
        ld      d,a
        inc     hl
        jr      nz, .ret32
        inc     de
        jr      .ret32

.pos_path:
        ;; positive: clamp if >= 0x80000000
        ld      a,d
        cp      #0x80
        jr      c, .ret32
        ld      d,#0x7F
        ld      e,#0xFF
        ld      h,#0xFF
        ld      l,#0xFF

.ret32:
        ;; SDCC expects hl:de for 32-bit return (swap halves)
        ex      de,hl
        ret
