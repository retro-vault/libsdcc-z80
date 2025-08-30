        ;; unsigned char to float (ieee-754 single) for sdcc z80
        ;; converts an 8-bit unsigned value (0..255) to 32-bit single-precision.
        ;; exact; truncation not applicable (no fractional input).
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module uchar2fs
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___uchar2fs
        ;; inputs:  (stack) unsigned char a (passed as 16-bit; low byte is value)
        ;; outputs: de:hl = (float)a  (IEEE-754 single)
        ;; clobbers: af, bc, de, hl
        .globl  ___uchar2fs
___uchar2fs:
        ; fetch return address and argument, then restore stack
        pop     de              ; DE <- return address
        pop     hl              ; HL <- (xx:aa), L = a (0..255), H may be 0
        push    hl
        push    de

        ; take only the low byte as the value; put it in L, zero H
        ld      a,l
        ld      l,a
        xor     a
        ld      h,a

        ; zero?
        or      l               ; A was 0, so this is just test L
        jr      nz, .nonzero
        ; return 0.0f
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.nonzero:
        ; sign = 0 for unsigned; B holds sign
        ld      b,#0x00

        ; normalize (put leading 1 at bit15); count shifts in C
        ld      c,#0x00
.norm:
        bit     7,h
        jr      nz, .normdone
        add     hl,hl           ; HL <<= 1
        inc     c
        jr      .norm
.normdone:
        ; exponent = 127 + (15 - C) = 142 - C
        ld      a,#142
        sub     c               ; A = exponent

        ; pack IEEE:
        ; D = (sign<<7) | (exp>>1)      (sign=0 here)
        rra                     ; A>>1, lsb -> carry
        ld      d,a             ; D = exp>>1 (sign=0 so just copy)

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
