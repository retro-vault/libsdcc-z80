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
        ;; inputs:  (stack) int a
        ;; outputs: de:hl = (float)a  (ieee-754 single)
        ;; clobbers: af, bc, de, hl
        .globl  ___sint2fs
        .globl  ___uint2fs
___sint2fs:
        ; pop return and argument
        pop     de              ; DE <- return address to caller
        pop     hl              ; HL <- a (signed 16-bit)

        ; zero shortcut
        ld      a,h
        or      l
        jr      nz, .nonzero
        ; push back caller ret and return 0.0f
        push    de
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.nonzero:
        ; record sign in B (0x80 if negative), make HL = unsigned magnitude
        ld      b,#0x00
        bit     7,h
        jr      z, .mag_ok
        ld      b,#0x80
        ; HL = -HL  (works for -32768 too -> 0x8000)
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        inc     hl
.mag_ok:
        ; restore caller return on stack so our RET works
        push    de

        ; call ___uint2fs(HL); caller cleans stack -> we'll pop arg after return
        push    hl              ; push unsigned magnitude as "unsigned int"
        call    ___uint2fs
        pop     bc              ; discard our pushed argument (caller cleanup)

        ; if negative, set sign bit in top byte (D |= 0x80)
        bit     7,b
        jr      z, .done
        set     7,d
.done:
        ret