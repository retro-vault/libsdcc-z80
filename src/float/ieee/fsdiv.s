;; float divide (ieee-754 single) for sdcc z80
        ;; result = a / b
        ;; denormals treated as 0; division by zero returns max finite.
        ;; 24-bit mantissa division producing 24 quotient bits.
        ;;
        ;; ABI (sdcccall(1)):
        ;;   a in regs: HLDE  (H=a3, L=a2, D=a1, E=a0)
        ;;   b on stack: 4 bytes pushed by caller (low word first)
        ;;   result in HLDE
        ;;   callee cleans b from stack
        ;;
        ;; clobbers: af, bc, de, hl, ix
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fsdiv
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___fsdiv
        .globl  __fp_retpop4
        .globl  __fp_unpack_sign_exps
        .globl  __fp_unpack_mant24_ab
        .globl  __fp_pack_norm
        .globl  __fp_zero32

;; ============================================================
;; Frame layout:
;;
;;   ix+7 : b3  (sign+exp high)
;;   ix+6 : b2  (exp low + mant high)
;;   ix+5 : b1
;;   ix+4 : b0
;;   ix+2,3: return address
;;   ix+0,1: saved ix
;;   ix-1 : H = a3        \  push hl
;;   ix-2 : L = a2        /
;;   ix-3 : D = a1        \  push de
;;   ix-4 : E = a0        /
;;   ix-5 : result sign
;;   ix-6 : result exponent
;;   ix-7  : mant_a[0] / rem[0]  (LSB)
;;   ix-8  : mant_a[1] / rem[1]
;;   ix-9  : mant_a[2] / rem[2]  (MSB, with implicit 1)
;;   ix-10 : mant_b[0]  (LSB, divisor)
;;   ix-11 : mant_b[1]
;;   ix-12 : mant_b[2]  (MSB, with implicit 1)
;;   ix-13 : quot[0]    (LSB)
;;   ix-14 : quot[1]
;;   ix-15 : quot[2]    (MSB)
;;   ix-16 : integer bit (0 or 1)
;; ============================================================

        ;; ___fsdiv
        ;; inputs:  a in HLDE, b on caller stack (4 bytes)
        ;; outputs: HLDE = IEEE-754 single quotient a / b
        ;; clobbers: af, bc, de, hl, ix
___fsdiv:
        push    ix
        ld      ix,#0
        add     ix,sp

        push    hl
        push    de

        ld      hl,#-12
        add     hl,sp
        ld      sp,hl

        ;; ---- extract result sign and exponents ----
        call    __fp_unpack_sign_exps

        ;; ---- check zero/denormal ----
        ld      a,c
        or      a
        jp      z,.ret_zero
        ld      a,b
        or      a
        jp      z,.ret_maxfin

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
        jp      nz,.div_exp_out
        ld      a,l
        or      a
        jp      z,.ret_zero
        cp      #255
        jp      nc,.ret_maxfin
        jr      .div_exp_ok

.div_exp_out:
        bit     7,h
        jp      nz,.ret_zero
        jp      .ret_maxfin

.div_exp_ok:
        ld      -6(ix),l

        ;; ---- build mantissas A/B (with implicit 1) ----
        call    __fp_unpack_mant24_ab

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
        jr      c,.int_bit_zero
        jr      nz,.int_bit_one
        ld      a,e
        cp      -11(ix)
        jr      c,.int_bit_zero
        jr      nz,.int_bit_one
        ld      a,c
        cp      -10(ix)
        jr      c,.int_bit_zero

.int_bit_one:
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
        jr      .div_start

.int_bit_zero:
        ld      a,-6(ix)
        dec     a
        jp      z,.ret_zero
        ld      -6(ix),a
        ld      -16(ix),#0

.div_start:
        ld      b,#24

.div_loop:
        sla     c
        rl      e
        rl      d
        jr      c,.div_do_sub

        ld      a,d
        cp      -12(ix)
        jr      c,.div_no_sub
        jr      nz,.div_do_sub
        ld      a,e
        cp      -11(ix)
        jr      c,.div_no_sub
        jr      nz,.div_do_sub
        ld      a,c
        cp      -10(ix)
        jr      c,.div_no_sub

.div_do_sub:
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
        jr      .div_shift_q

.div_no_sub:
        or      a

.div_shift_q:
        rl      -13(ix)
        rl      -14(ix)
        rl      -15(ix)
        djnz    .div_loop

        ;; ---- normalize and pack ----
        ld      b,-5(ix)
        ld      c,-6(ix)

        ld      a,-16(ix)
        or      a
        jr      z,.div_pack_noshift

        srl     -15(ix)
        rr      -14(ix)
        rr      -13(ix)

.div_pack_noshift:
        res     7,-15(ix)

        ld      e,-13(ix)
        ld      d,-14(ix)
        ld      l,-15(ix)
        call    __fp_pack_norm

        jr      .cleanup

.ret_zero:
        call    __fp_zero32
        jr      .cleanup

.ret_maxfin:
        ld      a,-5(ix)
        or      #0x7F
        ld      h,a
        ld      l,#0x7F
        ld      d,#0xFF
        ld      e,#0xFF

.cleanup:
        ld      sp,ix
        pop     ix
        jp      __fp_retpop4
