        ;; unsigned long to float (ieee-754 single) for sdcc z80
        ;; converts a 32-bit unsigned integer (0..4294967295) to 32-bit single.
        ;; exact sign (always 0), truncates low bits beyond mantissa (no rounding).
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module ulong2fs
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___ulong2fs
        ;; inputs:  (stack) unsigned long a  (pushed as: high word, then low word)
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, bc, de, hl
        .globl  ___ulong2fs
___ulong2fs:
        ; fetch return address + arg (low then high), restore ret on stack
        pop     de              ; DE <- return address
        pop     hl              ; HL <- low  word
        pop     bc              ; BC <- high word
        push    bc
        push    hl
        push    de

        ; zero?
        ld      a,b
        or      c
        or      h
        or      l
        jr      nz, .nonzero
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.nonzero:
        ; normalize 32-bit BC:HL so that B bit7 == 1
        ; count left shifts in E  (0..31)
        ld      e,#0x00
.norm:
        bit     7,b
        jr      nz, .norm_done
        add     hl,hl           ; HL <<= 1
        rl      c               ; C <<= 1 with carry from H
        rl      b               ; B <<= 1 with carry from C
        inc     e
        jr      .norm
.norm_done:
        ; exponent = 127 + (31 - shifts) = 158 - E
        ld      a,#158
        sub     e               ; A = exponent (8-bit)

        ; pack ieee single (sign=0)
        ; After normalization: value = 1.xxx * 2^(exp-127)
        ; mantissa[22:0] = bits 30..8 of BC:HL  -> (B&0x7F), C, H
        ; D = exp>>1
        rra                     ; A>>1, carry = exp LSB
        ld      d,a

        ; E = ((exp&1)<<7) | (B & 0x7F)
        ld      a,b
        and     #0x7F
        jr      nc, .e_no_set   ; carry still from rra
        or      #0x80
.e_no_set:
        ld      e,a

        ; low 16 of mantissa: H = C, L = H(original)
        ld      a,h             ; save original H (bits 15..8)
        ld      h,c             ; H = C (bits 23..16)
        ld      l,a             ; L = saved H (bits 15..8)
        ret
