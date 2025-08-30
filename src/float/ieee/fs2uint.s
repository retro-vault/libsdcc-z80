        ;; float -> unsigned int (ieee-754 single) for sdcc z80
        ;; converts 32-bit float to 16-bit unsigned int with truncation toward zero.
        ;; behavior:
        ;;   negative -> 0
        ;;   too small (|x| < 1) -> 0
        ;;   too large (x > 65535) -> 65535
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fs2uint
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; ___fs2uint
        ;; inputs:  (stack) float a  [low word, high word]
        ;; outputs: hl = (unsigned int)a
        ;; clobbers: af, bc, de, hl
        .globl  ___fs2uint
___fs2uint:
        ; pop return, fetch arg (low then high word), restore ret
        pop     de              ; DE <- return address
        pop     hl              ; HL <- low word (mantissa low 16)
        pop     bc              ; BC <- high word (sign/exp + mantissa high 7)
        push    bc
        push    hl
        push    de

        ; extract sign
        ld      a,b
        and     #0x80
        jr      z, .positive
        ; negative -> result 0
        xor     a
        ld      h,a
        ld      l,a
        ret

.positive:
        ; exponent e = ((B & 0x7F) << 1) | (C >> 7)
        ld      a,b
        and     #0x7F
        rla                     ; A = (B&0x7F) << 1, carry = original bit6
        ld      e,a             ; E = partial
        ld      a,c
        rlca                    ; move bit7 into carry? we just need bit7
        ; restore A = C
        ld      a,c
        ; (C >> 7) is 0 or 1 -> put into D
        and     #0x80
        jr      z, .e_low
        inc     e
.e_low:
        ; E now holds exponent (0..255). We need unbiased e := E - 127
        ld      a,e
        sub     #127
        ; if e < 0 => |x| < 1 -> 0
        jr      nc, .e_nonneg
        xor     a
        ld      h,a
        ld      l,a
        ret
.e_nonneg:
        ; clamp: if e >= 16 -> overflow for 16-bit unsigned
        cp      #16
        jr      c, .within_range
        ld      hl,#0xFFFF
        ret

.within_range:
        ; Build 24-bit mantissa M = 1<<23 | (mantissa bits)
        ; bytes: M2:M1:M0 = [0x80 | (C&0x7F)] : [H] : [L]
        ld      a,c
        and     #0x7F
        or      #0x80
        ld      d,a             ; D = M2
        ld      a,h
        ld      b,a             ; B = M1
        ld      a,l
        ld      c,a             ; C = M0

        ; Compute integer = M >> (23 - e)  if e <= 23
        ;                 = M << (e - 23)  if e > 23
        ; We only need 16-bit result in HL, trunc toward zero.

        ld      a,e             ; A = e
        cp      #24
        jr      c, .shift_right ; e <= 23
        ; left shift by (e-23)
        sub     #23             ; A = e-23  (0..15)
        ld      h,#0x00
        ld      l,#0x00
.lsh_loop:
        ; HL:BC <- (HL:BC << 1) using M2:M1:M0 in D:B:C
        ; start with 24-bit M in D:B:C, shift left A times, but we only keep top 16
        ; First iteration: put M into HL: we'll gather top bits into HL by shifting.
        ; We'll use D:B:C as working copy.
        add     a,#0            ; no-op to keep flags coherent
        ; shift D:B:C left by 1
        sla     c
        rl      b
        rl      d
        ; The top 16 bits currently in (D,B); capture into HL as we go by continuing loops
        dec     a
        jr      nz, .lsh_loop

        ; After shifts, integer is the top 16 bits of D:B:C >> 8 -> D:B
        ld      h,d
        ld      l,b
        ret

.shift_right:
        ; A = e (0..23), need sh = 23 - e (1..23)
        ld      a,#23
        sub     e               ; A = 23 - e
        ; Right shift M (24-bit D:B:C) by A, keep low 16 bits as result.
.rsh_loop:
        ; shift D:B:C right by 1
        srl     d
        rr      b
        rr      c
        dec     a
        jr      nz, .rsh_loop
        ; Result integer = the 16 low bits of D:B:C after shift -> B:C
        ld      h,b
        ld      l,c
        ret
