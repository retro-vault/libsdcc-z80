        ;; float -> signed long (ieee-754 single) for sdcc z80
        ;; converts 32-bit float to 32-bit signed int with truncation toward zero.
        ;; behavior:
        ;;   |x| < 1              -> 0
        ;;   x >=  2^31           ->  0x7FFFFFFF (clamp)
        ;;   x <= -2^31           ->  0x80000000 (clamp)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2slong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fs2slong
        ;; inputs:  (stack) float a
        ;; outputs: de:hl = (long)a
        ;; clobbers: af, bc, de, hl
        .globl  ___fs2slong
___fs2slong:
        pop     de              ; DE <- return
        pop     hl              ; HL <- low
        pop     bc              ; BC <- high
        push    bc
        push    hl
        push    de

        ; extract sign into A (0x80 if negative, else 0)
        ld      a,b
        and     #0x80
        ld      d,a             ; stash sign in D's bit7 temporarily (will be overwritten later)

        ; compute unbiased exponent e into C
        ld      a,b
        and     #0x7F
        rla
        ld      e,a
        ld      a,c
        and     #0x80
        jr      z, .no_inc
        inc     e
.no_inc:
        ld      a,e
        sub     #127            ; A = e
        jr      nc, .e_ok
        ; |x| < 1 -> 0
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret
.e_ok:
        ld      c,a             ; C = e

        ; Build X = (M << 8) = [M2:M1:M0:0] into DE:HL (we'll overwrite D shortly)
        ld      a,c             ; A = low byte of high word again? need mantissa from original C/H/L
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      e,h             ; E = M1 (from low word high)
        ld      h,l             ; H = M0 (from low word low)
        xor     a               ; A=0
        ld      l,a             ; L = 0
        ; D must be M2, but D currently holds sign; move sign to B first
        ld      b,d             ; B = sign (0x80 or 0)
        ld      d,#0            ; clear D before setting M2
        ld      d,a             ; D = 0 (A=0)
        ; reload M2 into D
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      d,a             ; D = M2

        ; Shift according to e in C
        ld      a,c
        cp      #24
        jr      c, .shr_path

        ; left shift by k = e - 23
        sub     #23
.lsh32:
        sla     l
        rl      h
        rl      e
        rl      d
        dec     a
        jr      nz, .lsh32
        jr      .apply_sign

.shr_path:
        ; right shift by k = 23 - e
        ld      a,#23
        sub     c
.rsh32:
        srl     d
        rr      e
        rr      h
        rr      l
        dec     a
        jr      nz, .rsh32

.apply_sign:
        ; B holds sign: 0x80 if negative else 0
        bit     7,b
        jr      z, .positive

        ; negative: value = - (DE:HL), but clamp at 0x80000000 if overflow
        ; DE:HL is magnitude (unsigned). If it exceeds 0x80000000, clamp.
        ; Check (DE:HL > 0x80000000) => (D > 0x80) or (D==0x80 && (E|H|L)!=0)
        ld      a,d
        cp      #0x80
        jr      c, .neg_ok      ; < 0x80xxxxxx
        jr      nz, .neg_clamp  ; > 0x80xxxxxx
        ; == 0x80xxxxxx : clamp if any low bits nonzero
        ld      a,e
        or      h
        or      l
        jr      z, .neg_exact   ; exactly 0x80000000 already
.neg_clamp:
        ld      d,#0x80
        ld      e,#0x00
        ld      h,#0x00
        ld      l,#0x00
        ret
.neg_exact:
        ; already 0x80000000
        ret
.neg_ok:
        ; two's complement negate
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        ld      a,e
        cpl
        ld      e,a
        ld      a,d
        cpl
        ld      d,a
        inc     hl
        jr      nz, .neg_done
        inc     de
.neg_done:
        ret

.positive:
        ; positive: clamp at 0x7FFFFFFF if >= 2^31
        ; Check e >= 31 would already have been left-shifted; simpler: compare DE:HL to 0x7FFFFFFF
        ld      a,d
        cp      #0x80
        jr      c, .pos_ok
        jr      nz, .pos_clamp
        ld      a,e
        or      h
        or      l
        jr      z, .pos_clamp   ; == 0x80000000 -> clamp down
.pos_ok:
        ret
.pos_clamp:
        ld      d,#0x7F
        ld      e,#0xFF
        ld      h,#0xFF
        ld      l,#0xFF
        ret
