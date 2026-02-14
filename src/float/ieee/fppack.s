        ;; shared float pack helper for sdcc z80
        ;;
        ;; inputs:
        ;;   B = sign mask (0x00 or 0x80)
        ;;   C = biased exponent (8-bit)
        ;;   L = mantissa high 7 bits (bit7 must be clear)
        ;;   D:E = mantissa low 16 bits
        ;;
        ;; outputs:
        ;;   H:L:D:E packed IEEE-754 single
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2026 tomaz stih

        .module fppack
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE
        .globl  __fp_pack_norm

        ;; __fp_pack_norm
        ;; inputs:  B=sign mask, C=biased exponent, L=mantissa hi7, DE=mantissa low16
        ;; outputs: HLDE = packed IEEE-754 single
        ;; clobbers: af, hl
__fp_pack_norm:
        ld      a,c
        rrca
        and     #0x80
        or      l
        ld      l,a

        ld      a,c
        srl     a
        or      b
        ld      h,a
        ret
