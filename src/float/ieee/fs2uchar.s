        ;; float -> unsigned char (ieee-754 single) for sdcc z80
        ;; implemented via ___fs2uint; returns low byte (truncate).
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2uchar
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fs2uchar
        .globl  ___fs2uint

        ;; ___fs2uchar
        ;; inputs:  (stack) float a
        ;; outputs: hl (L) = (unsigned char)a
        ;; clobbers: af, bc, de, hl
___fs2uchar:
        ; tail-call core and keep only L
        call    ___fs2uint
        ; HL already has uint16 result; L is the uchar
        ret
