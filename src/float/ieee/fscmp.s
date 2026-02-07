        ;; float compare (ieee-754 single) for sdcc z80
        ;; returns -1 if a<b, 0 if a==b, +1 if a>b
        ;; denormals treated as 0; NaN/Inf unsupported.
        ;;
        ;; ABI (observed):
        ;;   a in regs: HL:DE (H=a3, L=a2, D=a1, E=a0)
        ;;   b on stack: ret, b.low, b.high   (caller pushes b.high then b.low)
        ;;   return int16 in DE (caller does ex de,hl)
        ;;
        ;; clobbers: af, bc, de, hl, ix
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fscmp
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fscmp
___fscmp:
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; snapshot a into B,C,D,E so we never lose a1/a0
        ;; B=a3, C=a2, D=a1, E=a0
        ld      b,h
        ld      c,l
        ;; D,E already

        ;; ------------------------------------------------------------
        ;; stack layout after push ix:
        ;;   2(ix),3(ix) = return address
        ;;   4(ix),5(ix) = b.low   (b0=4(ix), b1=5(ix))
        ;;   6(ix),7(ix) = b.high  (b2=6(ix), b3=7(ix))
        ;; ------------------------------------------------------------

        ;; ---- compute biased exponents: EA in H, EB in L ----
        ;; EA = ((a3&0x7F)<<1) | (a2>>7)
        ld      a,b
        and     #0x7F
        rla
        ld      h,a
        ld      a,c
        and     #0x80
        jr      z, ea_ok
        inc     h
ea_ok:
        ;; EB = ((b3&0x7F)<<1) | (b2>>7)  (b3=7(ix), b2=6(ix))
        ld      a,7(ix)
        and     #0x7F
        rla
        ld      l,a
        ld      a,6(ix)
        and     #0x80
        jr      z, eb_ok
        inc     l
eb_ok:

        ;; ---- denormals treated as 0 (exp==0) ----
        ld      a,h
        or      a
        jr      nz, a_nz
        ld      a,l
        or      a
        jr      nz, a_zero_b_nz
        jp      ret0

a_zero_b_nz:
        ;; 0 vs nonzero: sign(b) decides (b3=7(ix))
        ld      a,7(ix)
        and     #0x80
        jr      z, retm1
        jr      retp1

a_nz:
        ld      a,l
        or      a
        jr      nz, both_nz
        ;; a!=0, b==0: sign(a) decides
        ld      a,b
        and     #0x80
        jr      z, retp1
        jr      retm1

both_nz:
        ;; ---- signs differ? ----
        ;; (a3 ^ b3) & 0x80
        ld      a,b
        xor     7(ix)
        and     #0x80
        jr      z, same_sign
        ;; different signs: positive is greater
        ld      a,b
        and     #0x80
        jr      z, retp1
        jr      retm1

same_sign:
        ;; ---- compare exponents (biased): H vs L ----
        ld      a,h
        cp      l
        jr      z, exp_equal

        ;; if negative: reversed
        bit     7,b
        jr      z, pos_exp

        ;; both negative
        ld      a,h
        cp      l
        jr      c, retp1
        jr      retm1
pos_exp:
        ld      a,h
        cp      l
        jr      c, retm1
        jr      retp1

exp_equal:
        ;; ------------------------------------------------------------
        ;; same sign, same exponent:
        ;; compare a2:a1:a0 vs b2:b1:b0
        ;; (safe because exponent equal => bit7 of a2/b2 equal too)
        ;;
        ;; IMPORTANT: preserve carry from CP -> use BIT for sign test
        ;; ------------------------------------------------------------

        ;; a2 vs b2
        ld      a,c
        cp      6(ix)
        jr      z, mant_mid

        bit     7,b
        jr      z, mant_pos_a2
        ;; negative reversed
        jr      c, retp1
        jr      retm1
mant_pos_a2:
        jr      c, retm1
        jr      retp1

mant_mid:
        ;; a1 vs b1
        ld      a,d
        cp      5(ix)
        jr      z, mant_low

        bit     7,b
        jr      z, mant_pos_a1
        ;; negative reversed
        jr      c, retp1
        jr      retm1
mant_pos_a1:
        jr      c, retm1
        jr      retp1

mant_low:
        ;; a0 vs b0
        ld      a,e
        cp      4(ix)
        jr      z, ret0

        bit     7,b
        jr      z, mant_pos_a0
        ;; negative reversed
        jr      c, retp1
        jr      retm1
mant_pos_a0:
        jr      c, retm1
        jr      retp1

retm1:
        ld      de,#0xFFFF
        jr      ret

ret0:
        ld      de,#0x0000
        jr      ret

retp1:
        ld      de,#0x0001
        ;; fallthrough

ret:
        pop     ix

        ;; stack at this point: retaddr, b.low, b.high
        pop     hl                      ;; return address
        pop     bc                      ;; discard b.low
        pop     bc                      ;; discard b.high
        push    hl
        ret
