;; float divide (ieee-754 single) for sdcc z80 - DEBUG V2
        ;; debug focuses on the final packed result

        .module fsdiv
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fsdiv

        .globl  _fdebug_store_a_b1
        .globl  _fdebug_store_a_b2
        .globl  _fdebug_store_a_b3
        .globl  _fdebug_store_a_b4
        .globl  _fdebug_store_hl_w1
        .globl  _fdebug_store_hl_w2
        .globl  _fdebug_store_de_w1
        .globl  _fdebug_store_de_w2
        .globl  _fdebug_store_bc_w1

___fsdiv:
        push    ix
        ld      ix,#0
        add     ix,sp

        push    hl
        push    de

        ld      hl,#-12
        add     hl,sp
        ld      sp,hl

        ;; ---- extract result sign ----
        ld      a,-1(ix)
        xor     7(ix)
        and     #0x80
        ld      -5(ix),a

        ;; ---- extract exponents ----
        ld      a,-1(ix)
        and     #0x7F
        rlca
        ld      c,a
        bit     7,-2(ix)
        jr      z,ea_done
        set     0,c
ea_done:
        ld      a,7(ix)
        and     #0x7F
        rlca
        ld      b,a
        bit     7,6(ix)
        jr      z,eb_done
        set     0,b
eb_done:

        ;; ---- check zero/denormal ----
        ld      a,c
        or      a
        jp      z,ret_zero
        ld      a,b
        or      a
        jp      z,ret_maxfin

        ;; ---- result exponent ----
        ld      h,#0
        ld      l,c
        ld      d,#0
        ld      e,b
        or      a
        sbc     hl,de
        ld      de,#127
        add     hl,de

        ld      a,h
        or      a
        jp      nz,div_exp_out
        ld      a,l
        or      a
        jp      z,ret_zero
        cp      #255
        jp      nc,ret_maxfin
        jr      div_exp_ok

div_exp_out:
        bit     7,h
        jp      nz,ret_zero
        jp      ret_maxfin

div_exp_ok:
        ld      -6(ix),l

        ;; ---- build mantissa A ----
        ld      a,-4(ix)
        ld      -7(ix),a
        ld      a,-3(ix)
        ld      -8(ix),a
        ld      a,-2(ix)
        and     #0x7F
        or      #0x80
        ld      -9(ix),a

        ;; ---- build mantissa B ----
        ld      a,4(ix)
        ld      -10(ix),a
        ld      a,5(ix)
        ld      -11(ix),a
        ld      a,6(ix)
        and     #0x7F
        or      #0x80
        ld      -12(ix),a

        ;; ---- zero quotient ----
        xor     a
        ld      -13(ix),a
        ld      -14(ix),a
        ld      -15(ix),a

        ;; ---- remainder = mant_a ----
        ld      d,-9(ix)
        ld      e,-8(ix)
        ld      c,-7(ix)

        ;; ---- integer bit ----
        ld      a,d
        cp      -12(ix)
        jr      c,int_bit_zero
        jr      nz,int_bit_one
        ld      a,e
        cp      -11(ix)
        jr      c,int_bit_zero
        jr      nz,int_bit_one
        ld      a,c
        cp      -10(ix)
        jr      c,int_bit_zero

int_bit_one:
        ld      a,c
        sub     -10(ix)
        ld      c,a
        ld      a,e
        sbc     a,-11(ix)
        ld      e,a
        ld      a,d
        sbc     a,-12(ix)
        ld      d,a
        ld      -16(ix),#1
        jr      div_start

int_bit_zero:
        ld      a,-6(ix)
        dec     a
        jp      z,ret_zero
        ld      -6(ix),a
        ld      -16(ix),#0

div_start:
        ld      b,#24

div_loop:
        sla     c
        rl      e
        rl      d
        jr      c,div_do_sub

        ld      a,d
        cp      -12(ix)
        jr      c,div_no_sub
        jr      nz,div_do_sub
        ld      a,e
        cp      -11(ix)
        jr      c,div_no_sub
        jr      nz,div_do_sub
        ld      a,c
        cp      -10(ix)
        jr      c,div_no_sub

div_do_sub:
        ld      a,c
        sub     -10(ix)
        ld      c,a
        ld      a,e
        sbc     a,-11(ix)
        ld      e,a
        ld      a,d
        sbc     a,-12(ix)
        ld      d,a
        scf
        jr      div_shift_q

div_no_sub:
        or      a

div_shift_q:
        rl      -13(ix)
        rl      -14(ix)
        rl      -15(ix)
        djnz    div_loop

        ;; ---- DEBUG: raw quotient before normalize ----
        ;; b1 = quot[2], b2 = quot[1], b3 = quot[0], b4 = int_bit
        ld      a,-15(ix)
        call    _fdebug_store_a_b1
        ld      a,-14(ix)
        call    _fdebug_store_a_b2
        ld      a,-13(ix)
        call    _fdebug_store_a_b3
        ld      a,-16(ix)
        call    _fdebug_store_a_b4

        ;; ---- normalize and pack ----
        ld      b,-5(ix)
        ld      c,-6(ix)

        ld      a,-16(ix)
        or      a
        jr      z,div_pack_noshift

        srl     -15(ix)
        rr      -14(ix)
        rr      -13(ix)

div_pack_noshift:
        res     7,-15(ix)

        ld      e,-13(ix)
        ld      d,-14(ix)
        ld      l,-15(ix)

        ld      a,c
        rrca
        and     #0x80
        or      l
        ld      l,a

        ld      a,c
        srl     a
        or      b
        ld      h,a

        ;; ---- DEBUG: final HLDE ----
        call    _fdebug_store_hl_w1    ; w1 = HL (byte3:byte2)
        call    _fdebug_store_de_w2    ; w2 = DE (byte1:byte0)

        jr      cleanup

ret_zero:
        ld      h,#0
        ld      l,#0
        ld      d,#0
        ld      e,#0
        jr      cleanup

ret_maxfin:
        ld      a,-5(ix)
        or      #0x7F
        ld      h,a
        ld      l,#0x7F
        ld      d,#0xFF
        ld      e,#0xFF

cleanup:
        ld      sp,ix
        pop     ix
        pop     bc
        pop     af
        pop     af
        push    bc
        ret