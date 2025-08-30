        ;; float compare (ieee-754 single) for sdcc z80
        ;; returns -1 if a<b, 0 if a==b, +1 if a>b
        ;; denormals treated as 0; NaN/Inf unsupported.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fscmp
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fscmp
        ;; inputs:  (stack) float a, float b
        ;;          stack layout (top first): ret, a.low(L/H), a.high(C/B), b.low(L/H), b.high(C/B)
        ;; outputs: hl = -1, 0, or +1
        ;; clobbers: af, bc, de, hl, ix
        .globl  ___fscmp
___fscmp:
        ld      ix,#0
        add     ix,sp

        ; ---- compute biased exponents EA->E, EB->D ----
        ; EA = ((Ba & 0x7F) << 1) | (Ca >> 7)
        ld      a,5(ix)
        and     #0x7F
        rla
        ld      e,a
        ld      a,4(ix)
        and     #0x80
        jr      z, Aexp_ok
        inc     e
Aexp_ok:
        ; EB = ((Bb & 0x7F) << 1) | (Cb >> 7)
        ld      a,9(ix)
        and     #0x7F
        rla
        ld      d,a
        ld      a,8(ix)
        and     #0x80
        jr      z, Bexp_ok
        inc     d
Bexp_ok:

        ; ---- zero / denormal checks (exp==0 => treat as 0) ----
        ld      a,e
        or      a
        jr      nz, A_nz
        ld      a,d
        or      a
        jr      nz, A_is_zero_B_nz
        ; both zero => equal
        xor     a
        ld      h,a
        ld      l,a
        ret
A_is_zero_B_nz:
        ; 0 vs nonzero: sign(b) decides
        ld      a,9(ix)
        and     #0x80
        jp      z, ret_neg1     ; 0 < +b
        jp      ret_pos1        ; 0 > -b
A_nz:
        ld      a,d
        or      a
        jr      nz, both_nz
        ; a!=0, b==0: sign(a) decides
        ld      a,5(ix)
        and     #0x80
        jp      z, ret_pos1     ; +a > 0
        jp      ret_neg1        ; -a < 0

both_nz:
        ; ---- signs ----
        ld      a,5(ix)
        and     #0x80
        ld      b,a             ; B = SA (0x80 or 0)
        ld      a,9(ix)
        and     #0x80
        ld      c,a             ; C = SB

        ; if signs differ: positive is greater
        ld      a,b
        xor     c
        jr      z, same_sign
        ; different signs
        ld      a,b
        or      a
        jp      z, ret_pos1     ; a positive, b negative -> a>b
        jp      ret_neg1        ; a negative, b positive -> a<b

same_sign:
        ; ---- compare exponents (biased) ----
        ld      a,e
        cp      d
        jr      z, exp_equal
        ; if positive: higher exponent => greater
        ; if negative: reversed
        ld      a,b
        or      a
        jr      z, pos_exp_cmp
        ; negative numbers: reversed compare
        ld      a,e
        cp      d
        jp      c, ret_pos1     ; ea<eb => |a|<|b| => with both neg, a>b
        jp      ret_neg1        ; ea>eb => a<b
pos_exp_cmp:
        ld      a,e
        cp      d
        jp      c, ret_neg1
        jp      ret_pos1

exp_equal:
        ; ---- build mantissas (implicit 1) ----
        ; Ma2:Ma1:Ma0 = (0x80 | (Ca&0x7F)) : Ah : Al
        ; Mb2:Mb1:Mb0 = (0x80 | (Cb&0x7F)) : Bh : Bl
        ld      a,4(ix)
        and     #0x7F
        or      #0x80
        ld      e,a             ; reuse E as Ma2 (safe now)
        ld      a,8(ix)
        and     #0x7F
        or      #0x80
        ld      d,a             ; D = Mb2

        ; compare Ma2 vs Mb2
        ld      a,e
        cp      d
        jr      z, mant_mid
        ; decide with sign
        ld      a,b
        or      a
        jr      z, mant_top_pos
        ; negative: reversed
        jr      c, ret_pos1     ; Ma2<Mb2 -> a>b (both neg)
        jp      ret_neg1
mant_top_pos:
        jr      c, ret_neg1     ; Ma2<Mb2 -> a<b
        jp      ret_pos1

mant_mid:
        ; compare mid: Ah vs Bh
        ld      a,3(ix)
        ld      h,a
        ld      a,7(ix)
        cp      h
        jr      z, mant_low
        ld      a,b
        or      a
        jr      z, mant_mid_pos
        ; negative: reversed
        jr      c, ret_pos1
        jp      ret_neg1
mant_mid_pos:
        jr      c, ret_neg1
        jp      ret_pos1

mant_low:
        ; compare low: Al vs Bl
        ld      a,2(ix)
        ld      h,a
        ld      a,6(ix)
        cp      h
        jr      z, equal
        ld      a,b
        or      a
        jr      z, mant_low_pos
        ; negative: reversed
        jr      c, ret_pos1
        jp      ret_neg1
mant_low_pos:
        jr      c, ret_neg1
        jp      ret_pos1

equal:
        xor     a
        ld      h,a
        ld      l,a
        ret

ret_neg1:
        ld      h,#0xFF
        ld      l,#0xFF
        ret

ret_pos1:
        ld      h,#0x00
        ld      l,#0x01
        ret
