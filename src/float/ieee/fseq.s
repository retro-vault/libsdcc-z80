        ;; float equal (ieee-754 single) for sdcc z80
        ;; returns 1 if a==b else 0; implemented via ___fscmp.
        ;;
        ;; ABI:
        ;;   a in regs HL:DE
        ;;   b on stack
        ;;   result in A (0/1)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fseq
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fseq
        .globl  ___fscmp

___fseq:
        call    ___fscmp                ; DE = -1,0,+1

        ;; A = 1 iff DE == 0
        ld      a,d
        or      e
        jr      nz, .false
        ld      a,#0x01
        ret
.false:
        xor     a
        ret
