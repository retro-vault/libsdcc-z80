        ;; float equal (ieee-754 single) for sdcc z80
        ;; returns 1 if a==b else 0; implemented via ___fscmp.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fseq
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fseq
        .globl  ___fscmp

        ;; ___fseq
        ;; inputs:  (stack) float a, float b
        ;; outputs: hl = 1 if equal, else 0
        ;; clobbers: af, bc, de, hl
___fseq:
        call    ___fscmp
        ld      a,h
        or      l
        jr      z, .eq
        xor     a
        ld      h,a
        ld      l,a
        ret
.eq:
        ld      h,#0x00
        ld      l,#0x01
        ret
