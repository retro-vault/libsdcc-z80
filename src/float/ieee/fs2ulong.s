        ;; float -> unsigned long (ieee-754 single) for sdcc z80
        ;; converts 32-bit float to 32-bit unsigned int with truncation toward zero.
        ;; behavior:
        ;;   negative          -> 0
        ;;   |x| < 1           -> 0
        ;;   x >= 2^32         -> 0xFFFFFFFF (clamp)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2ulong
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fs2ulong
        ;; inputs:  (stack) float a  [low word, then high word]
        ;; outputs: de:hl = (unsigned long)a
        ;; clobbers: af, bc, de, hl
        .globl  ___fs2ulong
___fs2ulong:
        ; pop return, fetch arg words, restore return
        pop     de              ; DE <- return address
        pop     hl              ; HL <- low  word (mantissa low 16)
        pop     bc              ; BC <- high word (sign/exp + mantissa high 7)
        push    bc
        push    hl
        push    de

        ; negative?  (sign bit in B)
        ld      a,b
        and     #0x80
        jr      z, .nonneg
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.nonneg:
        ; exponent e = (((B & 0x7F) << 1) | (C >> 7)) - 127
        ld      a,b
        and     #0x7F
        rla                     ; A = (B&0x7F) << 1, carry gets bit6
        ld      e,a             ; E = partial exponent
        ld      a,c
        and     #0x80
        jr      z, .e_done
        inc     e
.e_done:
        ld      a,e
        sub     #127            ; A = unbiased exponent e
        jr      nc, .e_ge_0
        ; |x| < 1  -> 0
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.e_ge_0:
        ; clamp if e >= 32  -> 0xFFFFFFFF
        cp      #32
        jr      c, .within32
        ld      de,#0xFFFF
        ld      hl,#0xFFFF
        ret

.within32:
        ; Build 24-bit mantissa M = 1<<23 | mantissa bits
        ; Bytes M2:M1:M0 = [0x80 | (C&0x7F)] : [H] : [L]
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      d,a             ; D = M2
        ld      a,h
        ld      b,a             ; B = M1
        ld      a,l
        ld      c,a             ; C = M0

        ; Form 32-bit X = (M << 8) so X bytes = [D : B : C : 0]
        ld      e,b             ; DE = D:B
        ld      h,c             ; HL = C:0
        xor     a
        ld      l,a

        ; if e <= 23: right shift by sh = 23 - e
        ; if e  > 23: left  shift by sh = e  - 23
        ld      a,e             ; A currently = partial exponent? no, E holds original partial exponent.
        ; We need unbiased e in a register: we have it in A from earlier compare path.
        ; Recompute e quickly:
        ld      a,e             ; E still holds ((B&0x7F)<<1 | (C>>7))
        sub     #127            ; A = e again
        cp      #24
        jr      c, .shift_right

        ; left shift by (e - 23)
        sub     #23             ; A = e - 23  (0..8)
.lsh_loop:
        ; 32-bit left shift: DE:HL <<= 1
        sla     l
        rl      h
        rl      e
        rl      d
        dec     a
        jr      nz, .lsh_loop
        ret

.shift_right:
        ; right shift by sh = 23 - e
        ld      a,#23
        sub     e               ; A = 23 - (partial exp) ?  careful: E had biased exp, not e.
        ; Fix: compute sh directly from unbiased e in A_before:
        ; We have A (unbiased e) from the cp above was <24, but we overwrote A.
        ; Recompute unbiased e into B, then sh = 23 - e.
        ; Recompute cleanly:
        ld      a,b             ; restore? B is mantissa M1 now.
        ; We'll recompute e again from high word BC saved on stack (not available).
        ; Simpler: we already had A=e before 'cp #24'. Save it.

        ; --- Fix: Save unbiased e into C' before branch ---
