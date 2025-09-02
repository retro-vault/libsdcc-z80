        ;; 16-bit multiply using shift-and-add with small-operand fast path
        ;; multiplies bc by de and returns the low 16 bits in de
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2000 michael hope
        ;; copyright (c) 2021 philipp klaus krause
        
        .module mul                               ; module name
        .optsdcc -mz80 sdcccall(1)
        .area   _CODE                             ; code segment

        .globl  __mulint                          ; export symbol

        ;; __mulint
        ;; inputs:  hl = multiplicand (16-bit), de = multiplier (16-bit)
        ;; outputs: de = product low word (via __mul16)
        ;; clobbers: a, b, c, h, l, f; preserves de on entry only logically
        ;; notes: moves hl→bc then calls the core 16-bit multiply
__mulint:
        ld      c, l                              ; c = low(multiplicand)
        ld      b, h                              ; b = high(multiplicand)

        ;; __mul16
        ;; inputs:  bc = multiplicand, de = multiplier
        ;; outputs: de = product low word
        ;; clobbers: a, b, c, h, l, f
        ;; notes: classic shift-add loop; fast path when b = 0 (8-bit)
__mul16::
        xor     a                                 ; a = 0
        ld      l, a                              ; l = 0, hl accumulates sum
        or      a, b                              ; set z if high byte of bc = 0
        ld      b, #16                            ; loop count = 16 bits by default
        jr      nz, 2$                            ; if high byte nonzero, use 16-bit path

        ld      b, #8                             ; fast path: only 8 bits in c
        ld      a, c                              ; preload a with c for rla
1$:
        add     hl, hl                            ; shift partial sum left
2$:
        rl      c                                 ; shift next bit of c into carry
        rla                                       ; shift a as well (fast path helper)
        jr      nc, 3$                            ; if bit was 0, skip add
        add     hl, de                            ; add multiplier to partial sum
3$:
        djnz    1$                                ; loop over all bits
        ex      de, hl                            ; move result low word to de
        ret                                       ; return with de = product low
