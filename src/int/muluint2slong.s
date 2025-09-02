        ;; 16x16 -> 32 unsigned multiply, returns de:hl (low:high)
        ;; shifts (iy:hl) left; if msb of multiplier set, adds de to low word
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2021 philipp klaus krause
		
        .module __muluint2slong                    ; module name
        .optsdcc -mz80 sdcccall(1)
        .area   _CODE                              ; code segment

        .globl  ___muluint2ulong                   ; export symbol

        ;; ___muluint2ulong
        ;; inputs:  hl = multiplier (u16), de = multiplicand (u16)
        ;; outputs: de:hl = product (u32) with de = low, hl = high
        ;; clobbers: b, iy, h, l, d, e, f
        ;; notes: uses shift-add algorithm; (iy:hl) holds partial product
___muluint2ulong:
        ld      iy, #0                             ; iy = low 16 of product
        ld      b, #16                             ; loop over 16 multiplier bits
loop:
        add     iy, iy                             ; (iy:hl) <<= 1, start with low
        adc     hl, hl                             ; then high with carry from iy
        jr      nc, skip                           ; if msb(multiplier bit) = 0, skip add
        add     iy, de                             ; add multiplicand to low word
        jr      nc, skip                           ; if carry into high, bump hl
        inc     hl                                 ; propagate carry into high word
skip:
        djnz    loop                               ; next bit
        push    iy                                 ; move low word into de
        pop     de
        ret                                        ; de:hl = product
