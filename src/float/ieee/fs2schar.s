        ;; float -> signed char (ieee-754 single) for sdcc z80
        ;; implemented via ___fs2sint; returns low byte (truncate).
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2schar
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fs2schar
        .globl  ___fs2sint

        ;; ___fs2schar
        ;; inputs:  (stack) float a
        ;; outputs: hl (L) = (signed char)a
        ;; clobbers: af, bc, de, hl
___fs2schar:
        call    ___fs2sint
        ; HL has int16; L is the schar (two's complement truncation)
        ret
