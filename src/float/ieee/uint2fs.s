        ;; unsigned int to float (ieee-754 single) for sdcc z80
        ;; converts a 16-bit unsigned int (0..65535) to 32-bit single-precision float.
        ;; exact; no fractional part to round. sign is always zero.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module uint2fs
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___uint2fs
        ;; inputs:  (stack) unsigned int a
        ;; outputs: de:hl = (float)a  (ieee-754 single)
        ;; clobbers: af, bc, de, hl
        .globl  ___uint2fs
___uint2fs:
        ; fetch return address and argument, then restore stack
        pop     de              ; DE <- return address
        pop     hl              ; HL <- a (unsigned 16-bit)
        push    hl
        push    de

        ; zero?
        ld      a,h
        or      l
        jr      nz, .nonzero
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.nonzero:
        ; sign = 0 (unsigned)
        ; normalize HL until bit15=1; count shifts in C
        ld      c,#0x00
.norm:
        bit     7,h
        jr      nz, .normdone
        add     hl,hl
        inc     c
        jr      .norm
.normdone:
        ; exponent = 127 + (15 - C) = 142 - C
        ld      a,#142
        sub     c               ; A = exponent

        ; pack ieee:
        ; D = (sign<<7) | (exp>>1)   (sign=0 here)
        rra                     ; A>>1, lsb -> carry
        ld      d,a

        ; E = ((exp&1)<<7) | (H & 0x7F)
        ld      a,h
        and     #0x7F
        jr      nc, .e_nocarry
        or      #0x80
.e_nocarry:
        ld      e,a

        ; low 16 bits of mantissa = L << 8 (truncate low 8)
        ld      h,l
        xor     a
        ld      l,a
        ret
