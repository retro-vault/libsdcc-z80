        ;; signed division helpers (8 and 16 bit), with remainder fixup
        ;; builds signed operands, divides via __divu16, fixes signs
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2000-2021 michael hope, philipp klaus krause
        
        .module divsigned                          ; module name
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE                              ; code segment

        .globl  __divsint                          ; export symbols
        .globl  __divschar

        ;; __divschar
        ;; inputs:  a = dividend (signed 8-bit), l = divisor (signed 8-bit)
        ;; outputs: de = quotient (signed 16-bit), hl = remainder (signed 16-bit)
        ;; clobbers: a, b, d, e, h, l, f; falls into __div8 / __div_signexte
        ;; notes: sign-extends both args into hl and de, then uses 16-bit core
__divschar:
        ld      e, l                              ; e = divisor (orig l)
        ld      l, a                              ; l = dividend low

        ;; __div8
        ;; inputs:  hl low contains dividend byte
        ;; action:  sign-extend dividend into h
__div8::
        ld      a, l                              ; prepare sign of dividend
        rlca                                     ; sign bit into carry
        sbc     a, a                             ; a = 00 or ff
        ld      h, a                             ; h = sign(dividend)

        ;; __div_signexte
        ;; inputs:  e contains divisor byte
        ;; action:  sign-extend divisor into d, then fall to __div16
__div_signexte:
        ld      a, e                              ; prepare sign of divisor
        rlca                                     ; sign bit into carry
        sbc     a, a                             ; a = 00 or ff
        ld      d, a                             ; d = sign(divisor)
        ;; fall through to __div16

        ;; __divsint / __div16
        ;; inputs:  hl = dividend (signed 16-bit), de = divisor (signed 16-bit)
        ;; outputs: de = quotient (signed 16-bit), hl = remainder (signed 16-bit)
        ;; clobbers: a, b, d, e, h, l, f
        ;; notes: take abs values, do unsigned divide, then fix signs
__divsint:
__div16::
        ld      a, h                              ; get high byte of dividend
        xor     a, d                              ; xor with high byte of divisor
        rla                                       ; carry = sign(quotient)
        ld      a, h                              ; restore high(dividend)
        push    af                                ; save quotient sign and div sign

        ; take absolute value of dividend
        rla                                       ; test sign(dividend)
        jr      nc, .chkde                        ; if positive, skip negate
        sub     a, a                              ; a = 0
        sub     a, l                              ; a = -low
        ld      l, a                              ; l = -low
        sbc     a, a                              ; a = ff if borrow
        sub     a, h                              ; a = -high - borrow
        ld      h, a                              ; h = -high

        ; take absolute value of divisor
.chkde:
        bit     7, d                              ; test sign(divisor)
        jr      z, .dodiv                         ; if positive, skip negate
        sub     a, a                              ; a = 0
        sub     a, e                              ; a = -low
        ld      e, a                              ; e = -low
        sbc     a, a                              ; a = ff if borrow
        sub     a, d                              ; a = -high - borrow
        ld      d, a                              ; d = -high

        ; divide absolute values (unsigned core)
.dodiv:
        call    __divu16                          ; de = q (unsigned), hl = r

.fix_quotient:
        ; negate quotient if it should be negative
        pop     af                                ; recover quotient sign
        ret     nc                                ; if positive, done
        ld      b, a                              ; save a
        sub     a, a                              ; a = 0
        sub     a, e                              ; a = -low(q)
        ld      e, a                              ; e = low(q) negated
        sbc     a, a                              ; a = ff if borrow
        sub     a, d                              ; a = -high(q) - borrow
        ld      d, a                              ; d = high(q) negated
        ld      a, b                              ; restore a
        ret

        ;; __get_remainder
        ;; inputs:  carry encodes sign(dividend) from prior rla
        ;; outputs: hl = remainder (signed 16-bit, sign matches dividend)
        ;; clobbers: a, d, e, f; de used as temp
__get_remainder::
        rla                                       ; carry -> sign(remainder?)
        ex      de, hl                            ; work on remainder in de
        ret     nc                                ; if positive, done
        sub     a, a                              ; a = 0
        sub     a, e                              ; a = -low(r)
        ld      e, a                              ; e = low(r) negated
        sbc     a, a                              ; a = ff if borrow
        sub     a, d                              ; a = -high(r) - borrow
        ld      d, a                              ; d = high(r) negated
        ret
