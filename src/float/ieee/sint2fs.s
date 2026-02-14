        ;; signed int to float via uint2fs (ieee-754 single) for sdcc z80
        ;; converts 16-bit signed int to 32-bit single precision by:
        ;;  - taking unsigned magnitude
        ;;  - calling ___uint2fs
        ;;  - setting sign bit in the result if input was negative
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module sint2fs
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___sint2fs
        ;; inputs:  hl = a (signed 16-bit)
        ;; outputs: hl:de = (float)a  (ieee-754 single, hl=high word, de=low word)
        ;; clobbers: af, bc, de, hl
        .globl  ___sint2fs
        .globl  ___uint2fs
        ;; ___sint2fs
___sint2fs:
        ;; zero shortcut
        ld      a,h
        or      l
        jr      nz, .nonzero
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.nonzero:
        ;; sign flag in B (0x80 if negative)
        ld      b,#0x00
        bit     7,h
        jr      z, .mag_ok
        ld      b,#0x80

        ;; HL = -HL  (two's complement; -32768 becomes 0x8000 which is fine)
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        inc     hl

.mag_ok:
        ;; convert magnitude
        call    ___uint2fs

        ;; apply sign to float: set sign bit in highest byte (H bit7)
        bit     7,b
        ret     z
        set     7,h
        ret
