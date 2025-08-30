        ;; float sub (ieee-754 single) for sdcc z80
        ;; computes a - b by flipping b's sign bit and tail-calling ___fsadd.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fssub
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fssub
        .globl  ___fsadd

        ;; ___fssub
        ;; inputs:  (stack) float a, float b
        ;; outputs: de:hl = a - b
        ;; clobbers: af, ix
___fssub:
        ld      ix,#0
        add     ix,sp
        ld      a,9(ix)         ; b.high high
        xor     #0x80           ; flip sign
        ld      9(ix),a
        jp      ___fsadd
