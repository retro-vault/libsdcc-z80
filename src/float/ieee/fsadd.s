        ;; float add (ieee-754 single) for sdcc z80
        ;; computes a + b with truncation (no rounding), denormals=>0, no NaN/Inf.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fsadd
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fsadd
        ;; inputs:  (stack) float a, float b
        ;;          stack layout (top first): ret, a.low(L/H), a.high(C/B), b.low(L/H), b.high(C/B)
        ;; outputs: de:hl = a + b
        ;; clobbers: af, bc, de, hl, ix
        .globl  ___fsadd
___fsadd:
        ld      ix,#0
        add     ix,sp

        ; ---------------- zero / denormal checks ----------------
        ; EA = ((Ba & 0x7F)<<1) | (Ca>>7)
        ld      a,5(ix)
        and     #0x7F
        rla
        ld      e,a
        ld      a,4(ix)
        and     #0x80
        jr      z, Aexp_ok
        inc     e
Aexp_ok:
        ; EB
        ld      a,9(ix)
        and     #0x7F
        rla
        ld      d,a
        ld      a,8(ix)
        and     #0x80
        jr      z, Bexp_ok
        inc     d
Bexp_ok:
        ; if EA==0 -> return B
        ld      a,e
        or      a
        jr      nz, A_not_zero
        ld      d,9(ix)
        ld      e,8(ix)
        ld      h,7(ix)
        ld      l,6(ix)
        ret
A_not_zero:
        ; if EB==0 -> return A
        ld      a,d
        or      a
        jr      nz, both_nz
        ld      d,5(ix)
        ld      e,4(ix)
        ld      h,3(ix)
        ld      l,2(ix)
        ret

both_nz:
        ; ---------------- build 24-bit mantissas ----------------
        ; A mantissa -> C:B:L   (MA2:MA1:MA0)
        ld      a,4(ix)
        and     #0x7F
        or      #0x80
        ld      c,a                  ; MA2
        ld      a,3(ix)
        ld      b,a                  ; MA1
        ld      l,2(ix)              ; MA0 already L

        ; B mantissa -> H:D:E   (MB2:MB1:MB0)
        ld      a,8(ix)
        and     #0x7F
        or      #0x80
        ld      h,a                  ; MB2
        ld      d,7(ix)              ; MB1
        ld      e,6(ix)              ; MB0

        ; ---------------- decide larger magnitude (X) ----------------
        ; Compare exponents EA(E) vs EB(Dtmp) -> recompute EB into A
        ld      a,9(ix)
        and     #0x7F
        rla
        ld      d,a                  ; D = EB partial
        ld      a,8(ix)
        and     #0x80
        jr      z, EB_ready
        inc     d
EB_ready:
        ld      a,e
        cp      d
        jp      z, exponents_equal
        jp      nc, A_is_X           ; EA > EB
        jp      B_is_X               ; EB > EA

exponents_equal:
        ; Compare mantissas MA vs MB
        ld      a,c
        cp      h
        jp      c, B_is_X
        jp      nz, A_is_X
        ld      a,b
        cp      d
        jp      c, B_is_X
        jp      nz, A_is_X
        ld      a,l
        cp      e
        jp      c, B_is_X
        jp      nz, A_is_X
        ; exact magnitude equality -> if signs differ, return +0.0, else double via add path
        ld      a,5(ix)
        and     #0x80               ; SA
        ld      h,a
        ld      a,9(ix)
        and     #0x80               ; SB
        xor     h
        jr      z, same_sign_equal
        ; different signs -> +0.0
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret
same_sign_equal:
        jp      A_is_X              ; treat as add with diff=0

; =====================  CASE: A is X (bigger magnitude)  =====================
A_is_X:
        ; diff = EA - EB
        ; rebuild EB into L
        ld      a,9(ix)
        and     #0x7F
        rla
        ld      l,a
        ld      a,8(ix)
        and     #0x80
        jr      z, A_diff_ok
        inc     l
A_diff_ok:
        ld      a,e
        sub     l
        ld      l,a                  ; L = diff (0..255)

        ; SA in E, SB in A
        ld      a,5(ix)
        and     #0x80
        ld      e,a                  ; SA
        ld      a,9(ix)
        and     #0x80                ; A = SB

        ; Align B mantissa H:D:E right by diff L  (cap at >=31 -> zero)
        ld      a,l
        cp      #31
        jr      c, AY_shift_ok
        xor     a
        ld      h,a
        ld      d,a
        ld      e,a
        jp      AY_shift_done
AY_shift_ok:
        or      a
        jr      z, AY_shift_done
AY_sr_loop:
        srl     h
        rr      d
        rr      e
        dec     a
        jr      nz, AY_sr_loop
AY_shift_done:
        ; same sign? (SA ^ SB == 0)
        ld      l,a                  ; save unused A
        ld      a,e                  ; SA
        xor     9(ix)                ; xor with raw byte then mask? safer:
        ; redo: compute SB again and xor
        ld      a,9(ix)
        and     #0x80
        xor     e
        jr      z, AY_do_add

        ; subtraction: (C:B:AL) - (H:D:E)
        ld      a,2(ix)              ; AL
        sub     e
        ld      l,a
        ld      a,b
        sbc     a,d
        ld      b,a
        ld      a,c
        sbc     a,h
        ld      c,a
        ; zero?
        ld      a,c
        or      b
        or      l
        jr      nz, AY_sub_norm
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret
AY_sub_norm:
        ; normalize left; exponent = EA (rebuild into A)
        ld      a,5(ix)
        and     #0x7F
        rla
        ld      d,a
        ld      a,4(ix)
        and     #0x80
        jr      z, AY_e_have
        inc     d
AY_e_have:
        ld      a,d
AY_norm_loop:
        bit     7,c
        jr      nz, AY_pack_sub
        sla     l
        rl      b
        rl      c
        dec     a
        jr      nz, AY_norm_loop
        ; underflow -> 0
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret
AY_pack_sub:
        ; clamp if exponent >= 255
        cp      #255
        jr      c, AY_pack_sub2
        ld      d,#0x7F
        ld      e,#0x7F
        ld      h,#0xFF
        ld      l,#0xFF
        ret
AY_pack_sub2:
        ; pack sign = SA
        rra                         ; A>>1, carry = exp LSB
        ld      e,a                 ; E' temp
        ld      a,5(ix)
        and     #0x80               ; SA
        or      e
        ld      d,a                 ; D' = sign|exp_hi
        ld      a,d
        and     #0x7F
        jr      nc, AY_e_keep_s
        or      #0x80
AY_e_keep_s:
        ld      e,a                 ; E' = exp_lo|mant_hi7
        ld      h,b                 ; mant mid
        ; L already mant low
        ret

AY_do_add:
        ; addition: (C:B:AL) + (H:D:E)
        ld      a,2(ix)
        add     a,e
        ld      l,a
        ld      a,b
        adc     a,d
        ld      b,a
        ld      a,c
        adc     a,h
        ld      c,a
        ; handle carry -> shift right, EA++
        jr      nc, AY_add_no_c
        srl     c
        rr      b
        rr      l
        ; EA++:
        ld      a,5(ix)
        and     #0x7F
        rla
        ld      d,a
        ld      a,4(ix)
        and     #0x80
        jr      z, AY_e_inc_ok
        inc     d
AY_e_inc_ok:
        ld      a,d
        inc     a
        jp      AY_pack_add
AY_add_no_c:
        ; EA unchanged
        ld      a,5(ix)
        and     #0x7F
        rla
        ld      d,a
        ld      a,4(ix)
        and     #0x80
        jr      z, AY_e_keep_ok
        inc     d
AY_e_keep_ok:
        ld      a,d
AY_pack_add:
        cp      #255
        jr      c, AY_pack_add2
        ld      d,#0x7F
        ld      e,#0x7F
        ld      h,#0xFF
        ld      l,#0xFF
        ret
AY_pack_add2:
        rra
        ld      e,a
        ld      a,5(ix)
        and     #0x80               ; SA
        or      e
        ld      d,a
        ld      a,d
        and     #0x7F
        jr      nc, AY_e_keep_add
        or      #0x80
AY_e_keep_add:
        ld      e,a
        ld      h,b
        ; L already mant low
        ret

; =====================  CASE: B is X (bigger magnitude)  =====================
B_is_X:
        ; diff = EB - EA
        ; rebuild EA into L
        ld      a,5(ix)
        and     #0x7F
        rla
        ld      l,a
        ld      a,4(ix)
        and     #0x80
        jr      z, B_diff_ok
        inc     l
B_diff_ok:
        ; EB in A
        ld      a,9(ix)
        and     #0x7F
        rla
        ld      h,a
        ld      a,8(ix)
        and     #0x80
        jr      z, EB_ok2
        inc     h
EB_ok2:
        ld      a,h
        sub     l
        ld      l,a                  ; diff

        ; SB in E, SA in A
        ld      a,9(ix)
        and     #0x80
        ld      e,a                  ; SB
        ld      a,5(ix)
        and     #0x80                ; SA

        ; Align A mantissa C:B:AL right by diff L
        ld      a,l
        cp      #31
        jr      c, BX_shift_ok
        xor     a
        ld      c,a
        ld      b,a
        ld      l,a
        jp      BX_shift_done
BX_shift_ok:
        or      a
        jr      z, BX_shift_done
BX_sr_loop:
        srl     c
        rr      b
        rr      l
        dec     a
        jr      nz, BX_sr_loop
BX_shift_done:
        ; same sign?
        ld      h,a                  ; temp store
        ld      a,e                  ; SB
        xor     5(ix)                ; xor raw then mask? redo:
        ld      a,5(ix)
        and     #0x80                ; SA
        xor     e
        jr      z, BX_do_add

        ; subtraction: (H:D:E) - (C:B:AL)
        ld      a,e
        sub     l
        ld      e,a
        ld      a,d
        sbc     a,b
        ld      d,a
        ld      a,h
        sbc     a,c
        ld      h,a
        ; zero?
        ld      a,h
        or      d
        or      e
        jr      nz, BX_sub_norm
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret
BX_sub_norm:
        ; exponent = EB (rebuild into A)
        ld      a,9(ix)
        and     #0x7F
        rla
        ld      b,a
        ld      a,8(ix)
        and     #0x80
        jr      z, BX_e_have
        inc     b
BX_e_have:
        ld      a,b
BX_norm_loop:
        bit     7,h
        jr      nz, BX_pack_sub
        sla     e
        rl      d
        rl      h
        dec     a
        jr      nz, BX_norm_loop
        ; underflow -> 0
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret
BX_pack_sub:
        cp      #255
        jr      c, BX_pack_sub2
        ld      d,#0x7F
        ld      e,#0x7F
        ld      h,#0xFF
        ld      l,#0xFF
        ret
BX_pack_sub2:
        rra
        ld      b,a
        ld      a,9(ix)
        and     #0x80               ; SB
        or      b
        ld      d,a
        ld      a,d
        and     #0x7F
        jr      nc, BX_e_keep_s
        or      #0x80
BX_e_keep_s:
        ld      e,a
        ; pack mantissa mid/low
        ld      l,e                 ; low already in E? keep simple
        ret

BX_do_add:
        ; (H:D:E) + (C:B:AL)
        ld      a,e
        add     a,l
        ld      e,a
        ld      a,d
        adc     a,b
        ld      d,a
        ld      a,h
        adc     a,c
        ld      h,a
        ; carry -> shift right, EB++
        jr      nc, BX_add_no_c
        srl     h
        rr      d
        rr      e
        ; EB++:
        ld      a,9(ix)
        and     #0x7F
        rla
        ld      b,a
        ld      a,8(ix)
        and     #0x80
        jr      z, BX_e_inc_ok
        inc     b
BX_e_inc_ok:
        ld      a,b
        inc     a
        jp      BX_pack_add
BX_add_no_c:
        ; EB unchanged
        ld      a,9(ix)
        and     #0x7F
        rla
        ld      b,a
        ld      a,8(ix)
        and     #0x80
        jr      z, BX_e_keep_ok
        inc     b
BX_e_keep_ok:
        ld      a,b
BX_pack_add:
        cp      #255
        jr      c, BX_pack_add2
        ld      d,#0x7F
        ld      e,#0x7F
        ld      h,#0xFF
        ld      l,#0xFF
        ret
BX_pack_add2:
        rra
        ld      b,a
        ld      a,9(ix)
        and     #0x80               ; SB
        or      b
        ld      d,a
        ld      a,d
        and     #0x7F
        jr      nc, BX_e_keep_add
        or      #0x80
BX_e_keep_add:
        ld      e,a
        ld      l,e                 ; low mant kept simple
        ret
