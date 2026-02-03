        ;; float less-than (ieee-754 single) for sdcc z80
        ;; returns 1 if a<b else 0; implemented via ___fscmp.
        ;;
        ;; ABI (observed):
        ;;   a in regs: HL:DE (H=a3, L=a2, D=a1, E=a0)
        ;;   b is pushed by caller (see compiler output)
        ;;   return boolean in A (caller tests A)
        ;;
        ;; IMPORTANT:
        ;;   do NOT clean b from the stack here; caller does "pop de"
        ;;   and later restores SP from IX in the surrounding function.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fslt
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fslt
        .globl  ___fscmp

___fslt:
        call    ___fscmp

        ;; ___fscmp returns int16 in DE:
        ;;   -1 => 0xFFFF  (a<b)
        ;;    0 => 0x0000
        ;;   +1 => 0x0001
        ;;
        ;; return 1 in A iff DE == 0xFFFF
        ld      a,d
        and     e
        inc     a               ;; 0xFF&0xFF=0xFF -> inc => 0x00 (Z=1) => true
        jr      nz, .false
        ld      a,#0x01
        ret
.false:
        xor     a
        ret
