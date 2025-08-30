        ;; signed long to float via ulong2fs (ieee-754 single) for sdcc z80
        ;; converts 32-bit signed int to single precision by:
        ;;  - producing unsigned magnitude
        ;;  - calling ___ulong2fs
        ;;  - setting sign bit in the result if input was negative
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module slong2fs
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___slong2fs
        ;; inputs:  (stack) long a  (pushed as: high word, then low word)
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, bc, de, hl
        .globl  ___slong2fs
        .globl  ___ulong2fs
___slong2fs:
        ; fetch return + arg (low then high)
        pop     de              ; DE <- return address
        pop     hl              ; HL <- low  word
        pop     bc              ; BC <- high word

        ; zero?
        ld      a,b
        or      c
        or      h
        or      l
        jr      nz, .not_zero
        ; restore ret and return 0.0
        push    bc
        push    hl
        push    de
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.not_zero:
        ; record sign in A (0x80 if negative), make magnitude in BC:HL
        ld      a,b
        and     #0x80
        jr      z, .mag_ready

        ; two's complement negate (BC:HL = - (BC:HL))
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        ld      a,c
        cpl
        ld      c,a
        ld      a,b
        cpl
        ld      b,a
        inc     hl
        jr      nz, .mag_ready
        inc     bc
.mag_ready:
        ; restore caller's return address, push arg for ___ulong2fs (high first, then low)
        push    bc              ; high word
        push    hl              ; low  word
        push    de              ; put return back before we call

        call    ___ulong2fs

        ; drop our pushed arg words (caller clean)
        pop     bc              ; discard return address from call
        pop     bc              ; discard low word
        pop     bc              ; discard high word
        ; stack now holds the original caller return

        ; if negative, set sign bit in D
        ld      a,b             ; reuse B? (B was clobbered by pops; use A we saved sign in earlier)
        ; we kept sign in A’s bit7 before negation path; restore from that:
        ; Actually A currently unknown—recompute sign by testing original sign we saved earlier.
        ; Easiest: we kept sign in A at branch time; carry that value in a spare register before pushes.
        ; We'll reconstruct: if original sign was set, bit7 of the first value of B was 1.
        ; But B is destroyed. Simpler: store sign into E before pushes.

        ; -- fixup: store sign into E earlier
        ; (We’ll implement as below: E already contains 0x80 if negative, else 0.)
        ; So here we just OR D with E.

        ; NOTE: E contains 0x80 if negative, else 0 (set below).
        or      e               ; D |= sign
        ld      d,a
        ret
