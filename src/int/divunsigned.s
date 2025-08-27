        ;; unsigned division helpers (8 and 16 bit), shift-subtract core
        ;; provides __divuchar (8/8) and __divuint (16/16), with two paths
        ;; optimized for small or large divisors
        ;;
        ;; code from sdcc project (origin: gbdk by pascal felber)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2000-2021 michael hope, philipp klaus krause,
        ;; marco bodrato
        
        .module divunsigned                       ; module name
        .optsdcc -mz80 sdcccall(1)                ; sdcc z80, sdcccall(1) abi
        .area   _CODE                             ; code segment

        .globl  __divuint                         ; export symbols
        .globl  __divuchar

        ;; __divuchar
        ;; inputs:  a = dividend (8-bit), l = divisor (8-bit)
        ;; outputs: l = remainder (8-bit), e = quotient (8-bit)
        ;; clobbers: a, d, e, h, l, f; falls into __divu8
        ;; notes: builds hl<-dividend, de<-divisor for 8-bit core
__divuchar:
        ld      e, l                              ; e = divisor (orig l)
        ld      l, a                              ; l = dividend (from a)
        ;; fall through to 8-bit unsigned divide core
__divu8:
        ld      h, #0x00                          ; hl = dividend (zero-extend)
        ld      d, h                              ; de = divisor (zero-extend)
        ;; fall through to __divu16

        ;; __divuint / __divu16
        ;; inputs:  hl = dividend (16-bit), de = divisor (16-bit)
        ;; outputs: de = quotient (16-bit), hl = remainder (16-bit), carry=0
        ;; clobbers: a, b, d, e, h, l, f
        ;; notes: chooses fast path when divisor < 2^7, else wide path
__divuint:
__divu16:
        ld      a, e                              ; test high bit of divisor
        and     a, #0x80                          ; keep bit7 of e
        or      a, d                              ; or high byte d
        jr      nz, .morethan7bits                ; if >= 2^7, use wide path

        ;; unsigned 16 by 7-bit division (fast path)
.atmost7bits:
        ld      b, #16                            ; 16 dividend bits
        adc     hl, hl                            ; carry is 0 here, see above
.dvloop7:
        rla                                       ; a <<= 1, carry <= msb(dividend)
        sub     a, e                              ; tentative remainder -= divisor
        jr      nc, .nodrop7                      ; if no borrow, keep it
        add     a, e                              ; else restore remainder
.nodrop7:
        ccf                                       ; 1 if subtraction succeeded
        adc     hl, hl                            ; shift next quotient bit in
        djnz    .dvloop7
        ld      e, a                              ; de = remainder, hl = quotient
        ex      de, hl                            ; de = quotient, hl = remainder
        ret

        ;; unsigned 16 by (>= 2^7) division (wide path)
.morethan7bits:
        ld      b, #9                             ; at most 9 quotient bits
        ld      a, l                              ; pre-shift: rotate 8 then undo 1
        ld      l, h
        ld      h, #0
        rr      l
.dvloop:
        adc     hl, hl                            ; shift remainder left
        sbc     hl, de                            ; try remainder -= divisor
        jr      nc, .nodrop                       ; keep if no borrow
        add     hl, de                            ; else restore remainder
.nodrop:
        ccf                                       ; 1 if subtraction succeeded
        rla                                       ; shift quotient bit into a
        djnz    .dvloop
        rl      b                                 ; capture 9th quotient bit
        ld      d, b                              ; d:e = quotient
        ld      e, a
        ret
