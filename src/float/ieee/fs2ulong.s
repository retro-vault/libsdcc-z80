        ;; float -> unsigned long (ieee-754 single) for sdcc z80
        ;; converts 32-bit float to 32-bit unsigned int with truncation toward zero.
        ;; behavior:
        ;;   negative          -> 0
        ;;   |x| < 1           -> 0
        ;;   x >= 2^32         -> 0xFFFFFFFF (clamp)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2ulong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fs2ulong
        ;; inputs:  float a in hl:de (observed mk_f32 chain)
        ;; outputs: hl:de = (unsigned long)a   (sdcc expected, same as fs2slong fix)
        ;; clobbers: af, bc, de, hl
        .globl  ___fs2ulong
___fs2ulong:
        ;; arrange: HL = low word, DE = high word
        ex      de,hl                   ;; HL = low, DE = high

        ;; negative? sign bit in D
        ld      a,d
        and     #0x80
        jr      z, .nonneg

        ;; negative -> 0
        xor     a
        ld      d,a
        ld      e,a
        ld      h,a
        ld      l,a
        jr      .ret32

.nonneg:
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
        jr      .ret32

.e_nonneg:
        ;; clamp if e >= 32 -> 0xFFFFFFFF
        ld      a,c
        cp      #32
        jr      c, .build_mag
        ld      d,#0xFF
        ld      e,#0xFF
        ld      h,#0xFF
        ld      l,#0xFF
        jr      .ret32

.build_mag:
        ;; build 24-bit mantissa into 32-bit magnitude DE:HL:
        ;; DE:HL = 0 : M2 : M1 : M0
        ;; M2 = (E & 0x7F) | 0x80   (E is low byte of high word)
        ;; M1:M0 = low word = HL currently
        ld      a,e
        and     #0x7F
        or      #0x80
        ld      e,a
        ld      d,#0x00

        ;; shift based on e (C) relative to 23
        ld      a,c
        cp      #23
        jr      z, .ret32_internal
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
        jr      .ret32_internal

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

.ret32_internal:
        ;; at this point, DE:HL is the magnitude value

.ret32:
        ;; SDCC expects hl:de for 32-bit return (same fix as fs2slong)
        ex      de,hl
        ret
