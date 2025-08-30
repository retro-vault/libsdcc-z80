        ;; float less-than (ieee-754 single) for sdcc z80
        ;; returns 1 if a<b else 0; implemented via ___fscmp.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fslt
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fslt
        .globl  ___fscmp

        ;; ___fslt
        ;; inputs:  (stack) float a, float b
        ;; outputs: hl = 1 if a<b, else 0
        ;; clobbers: af, bc, de, hl
___fslt:
        call    ___fscmp
        ld      a,h
        bit     7,a             ; negative -> a<b
        jr      z, .ge
        ld      h,#0x00
        ld      l,#0x01
        ret
.ge:
        xor     a
        ld      h,a
        ld      l,a
        ret
