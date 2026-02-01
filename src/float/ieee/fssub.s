        ;;
        ;; float sub (ieee-754 single) for sdcc z80 (sdcccall(1))
        ;;
        ;; computes a - b by flipping b's sign bit and tail-calling ___fsadd.
        ;;
        ;; ABI (same as ___fsadd):
        ;;   a in regs:  dehl = a0,a1,a2,a3 (little endian bytes)
        ;;   b on stack: push hl (b2,b3), push bc (b0,b1), call ___fssub
        ;;   callee cleanup is performed by ___fsadd (tail call).
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih
        ;;

        .module fssub
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fssub
        .globl  ___fsadd

___fssub::
        ld      ix,#0
        add     ix,sp

        ;; b3 is at 5(ix): [retlo,rethi,b0,b1,b2,b3]
        ld      a,5(ix)
        xor     #0x80
        ld      5(ix),a

        jp      ___fsadd
