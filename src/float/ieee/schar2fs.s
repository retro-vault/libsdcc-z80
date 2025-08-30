        ;; signed char to float (ieee-754 single) for sdcc z80
        ;; converts an 8-bit signed value (-128..127) to 32-bit single-precision.
        ;; implemented by sign-extending to 16-bit and tail-calling ___sint2fs.
        ;; minimal code size, reuses existing converter.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module schar2fs
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___schar2fs
        ;; inputs:  (stack) signed char a  (passed as 16-bit; value in L)
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, de, hl
        .globl  ___schar2fs
        .globl  ___sint2fs
___schar2fs:
        ; fetch return address and 16-bit arg, then restore stack
        pop     de              ; DE <- return address
        pop     hl              ; HL <- (xx:aa) with L = signed char
        ; sign-extend from L into H
        ld      a,l
        add     a,a             ; copy sign to carry
        sbc     a,a             ; A = 0x00 or 0xFF based on sign
        ld      h,a
        ; put adjusted arg and return addr back, then tail-call ___sint2fs
        push    hl
        push    de
        jp      ___sint2fs      ; tail call keeps original return address
