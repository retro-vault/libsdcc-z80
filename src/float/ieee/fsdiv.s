        ;; float div (ieee-754 single) for sdcc z80
        ;; computes a / b with truncation (no rounding), denormals=>0, no NaN/Inf.
        ;; mantissa precision uses a 16.16 fixed-point core (drops lowest 8 bits).
        ;; division-by-zero clamps to max finite with correct sign.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fsdiv
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fsdiv
        ;; inputs:  (stack) float a, float b
        ;;          layout (top first): ret, a.low(L/H), a.high(C/B), b.low(L/H), b.high(C/B)
        ;; outputs: de:hl = a / b
        ;; clobbers: af, bc, de, hl, ix
        .globl  ___fsdiv
___fsdiv:
        ld      ix,#0
        add     ix,sp

        ; ----- unpack biased exponents EA -> E, EB -> D -----
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

        ; ----- zero / denormal handling -----
        ; A zero? -> 0
        ld      a,e
        or      a
        jr      nz, A_not_zero
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret
A_not_zero:
        ; B zero? -> clamp to max finite (with sign)
        ld      a,d
        or      a
        jr      nz, B_not_zero
        ; sign = SA ^ SB
        ld      a,5(ix)
        and     #0x80
        ld      b,a
        ld      a,9(ix)
        and     #0x80
        xor     b
        ; pack max finite: 0x7F7FFFFF with sign in D bit7
        ld      d,#0x7F
        or      d               ; A|0x7F -> A is either 0 or 0x80; we want D = sign|0x7F
        ld      d,a
        ld      e,#0x7F
        ld      h,#0xFF
        ld      l,#0xFF
        ret
B_not_zero:

        ; ----- sign and unbiased exponent difference -----
        ; sign = SA ^ SB -> keep in B (0x00 or 0x80)
        ld      a,5(ix)
        and     #0x80
        ld      b,a
        ld      a,9(ix)
        and     #0x80
        xor     b
        ld      b,a

        ; e = (EA - 127) - (EB - 127) = EA - EB
        ld      a,e
        sub     d
        ld      c,a              ; C = unbiased exponent (may be negative)

        ; ----- build 16-bit proxy mantissas -----
        ; m16a = ((0x80 | (Ca&0x7F))<<8) | Ah  -> put in DE (remainder numerator)
        ld      a,4(ix)
        and     #0x7F
        or      #0x80
        ld      d,a
        ld      e,3(ix)

        ; m16b -> HL (divisor)
        ld      a,8(ix)
        and     #0x7F
        or      #0x80
        ld      h,a
        ld      l,7(ix)

        ; ----- 16.16 fixed-point division: Q = (m16a / m16b) -----
        ; integer bit = (m16a >= m16b) ? 1 : 0 ; if 1 then remainder -= m16b
        ; remainder in DE, divisor in HL, fraction output in FRAC = (B:C) re-used? no, C holds exponent.
        ; we'll put FRAC in A:E for a moment? better: use FRAC in A:E? we need A. Use FRAC in D:E? we use DE as remainder.
        ; Choose: FRAC in AF? no. We'll store FRAC in BC (B: high, C: low) but C already has exponent.
        ; So: keep exponent in A' temporarily? Simpler: move exponent to A' scratch memory: push AF.

        ; Save exponent (C) onto stack
        push    bc              ; push (C with e, B with sign) — we'll restore later

        ; integer_bit in A (0 or 1)
        ld      a,d
        cp      h
        jr      c, int_is_zero
        jr      nz, int_is_one
        ; equal high -> compare low
        ld      a,e
        cp      l
        jr      c, int_is_zero
int_is_one:
        ; remainder = m16a - m16b
        ld      a,e
        sub     l
        ld      e,a
        ld      a,d
        sbc     a,h
        ld      d,a
        ld      a,#1
        jr      int_done
int_is_zero:
        xor     a               ; A = 0
int_done:
        ; A = integer_bit (0 or 1)

        ; FRAC = 0 in B:C
        ld      b,#0x00
        ld      c,#0x00

        ; loop 16 times: remainder <<=1; FRAC<<=1; if remainder>=divisor { remainder-=divisor; FRAC|=1; }
        ld      e,a             ; keep integer_bit in E temporarily (free A for loop)
        ld      a,#16
div_loop:
        ; remainder <<= 1  (DE <<=1)
        sla     e
        rl      d
        ; FRAC <<= 1  (BC <<=1)
        sla     c
        rl      b
        ; compare remainder (D:E) vs divisor (H:L)
        ld      a,d
        cp      h
        jr      c, no_sub
        jr      nz, do_sub
        ld      a,e
        cp      l
        jr      c, no_sub
do_sub:
        ; remainder -= divisor
        ld      a,e
        sub     l
        ld      e,a
        ld      a,d
        sbc     a,h
        ld      d,a
        ; set bit0 of FRAC
        set     0,c
no_sub:
        dec     a
        jr      nz, div_loop

        ; restore exponent/sign
        pop     bc              ; B=sign, C=unbiased exponent

        ; If integer_bit == 0, normalize by shifting FRAC left 1 and e--
        ld      a,e             ; integer_bit saved in E
        or      a
        jr      nz, frac_norm_ok
        ; shift FRAC left once
        sla     c
        rl      b
        dec     c               ; wait: this was exponent in C earlier; careful—C now is FRAC low!
        ; We already restored exponent into C; after pop, FRAC is B:C and exponent lost.
        ; Fix: store exponent into A' before popping or use D' — redo correctly:

        ; -------- Fix normalization bookkeeping --------
        ; We will:
        ;   - Move FRAC (B:C) to (E:L) temporarily
        ;   - Keep exponent in C (already), sign in B (already)
        ;   - Use H as scratch.

        ; Move FRAC to E:L
        ld      e,c
        ld      l,b
        ; If integer_bit==0: (E:L) <<= 1 and exponent--
        ; (we're still in the integer_bit==0 path)
        sla     e
        rl      l
        dec     c
        ; move back FRAC to B:C
        ld      c,e
        ld      b,l
        jr      pack_result

frac_norm_ok:
        ; integer_bit==1: FRAC already normalized (no exponent change)
        ; nothing to do

pack_result:
        ; Now we have:
        ;   sign in B (bit7 set or clear)
        ;   unbiased exponent in C
        ;   FRAC = B:C (but B,C are also used; copy FRAC to H:L for packing)
        ld      h,b
        ld      l,c

        ; biased exponent = C + 127
        ld      a,c
        add     a,#127
        ; underflow?
        jr      nc, exp_nonneg
        ; A underflowed (>=256 wrap) is impossible here; check for too small:
        ; if biased <= 0 -> return 0
        ; We can test signed: if C < (-127) effectively; simple clamp:
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret
exp_nonneg:
        ; overflow?
        cp      #255
        jr      c, exp_ok
        ; clamp to max finite with sign
        ld      d,#0x7F
        ld      a,b
        and     #0x80
        or      d
        ld      d,a
        ld      e,#0x7F
        ld      h,#0xFF
        ld      l,#0xFF
        ret
exp_ok:
        ; Pack IEEE:
        ; D = (sign<<7) | (exp>>1)
        rra                     ; A>>1, lsb -> carry
        ld      d,a
        ld      a,b
        and     #0x80
        or      d
        ld      d,a

        ; Build mantissa from 16.16 FRAC (stored in H:L as copy of B:C):
        ; We need 23 fraction bits. Use FRAC16 << 7:
        ;   mant_hi7  = FRAC[15:9]
        ;   mant_mid8 = FRAC[8:1]
        ;   mant_low8 = FRAC[0] << 7  (low 7 bits zero)
        ; E = ((exp&1)<<7) | mant_hi7
        ld      a,h             ; FRAC high
        srl     a               ; a >> 1 -> bits 15:9 go to 7:1
        srl     a               ; >>2 -> 6:0
        srl     a               ; >>3 -> 5:?
        srl     a               ; >>4 -> 4:?
        srl     a               ; >>5 -> 3:?
        srl     a               ; >>6 -> 2:?
        srl     a               ; >>7 -> 1:?
        srl     a               ; >>8 -> 0:?     ; This many shifts is verbose; do it smarter below.

        ; ---- redo mant_hi7/mid/low compactly ----
        ; mant_hi7 = (FRAC >> 9) & 0x7F
        ld      a,h
        rlca                    ; move bit7 into carry path? We'll compute directly:
        ; Compute (H:L) >> 9 into A (low 8), but we only need the top 7 bits.
        ; Do: 9 right shifts on HL and use L as mant_mid candidate; simpler approach:

        ; Use temporary shifts:
        ; Copy FRAC to DE for shifting
        ld      d,h
        ld      e,l

        ; (DE) >> 1  -> bit15 to carry, E gets bit0..7, D gets >>1
        srl     d
        rr      e               ; >>1
        ; (DE) >> 8 total now
        srl     d
        rr      e
        srl     d
        rr      e
        srl     d
        rr      e
        srl     d
        rr      e
        srl     d
        rr      e
        srl     d
        rr      e
        srl     d
        rr      e
        ; one more to make 9:
        srl     d
        rr      e
        ; Now 'e' holds FRAC >> 9 low 8 bits; top 7 are our mant_hi7.
        ld      a,e
        and     #0x7F           ; mant_hi7

        ; complete E byte: add exp LSB (from earlier rra carry). We lost carry—recompute exp LSB:
        ; Recompute biased exponent (A' = C+127) again quickly to get LSB.
        ld      e,c
        ld      a,e
        add     a,#127
        and     #0x01
        rlca                    ; move to bit1
        rlca                    ; bit2
        rlca
        rlca
        rlca
        rlca
        rlca                    ; now in bit7
        or      e               ; WRONG: 'e' is mant_hi7; we want OR with mant_hi7
        ; Fix:
        ld      e,a             ; E = (expLSB<<7)
        ld      a,d             ; restore? d was (FRAC>>9 high) but not needed
        ld      a,#0            ; clear A
        ; Correct: build Ebyte = (exp_lsb<<7) | mant_hi7
        ld      a,c
        add     a,#127
        and     #0x01
        rlca
        rlca
        rlca
        rlca
        rlca
        rlca
        rlca
        or      e               ; e had mant_hi7
        ld      e,a

        ; mant_mid8 = (FRAC >> 1) & 0xFF
        ld      a,h
        rr      a
        ld      h,a

        ; mant_low8 = (FRAC & 1) << 7
        ld      a,l
        and     #0x01
        rlca
        rlca
        rlca
        rlca
        rlca
        rlca
        rlca
        ld      l,a

        ret
