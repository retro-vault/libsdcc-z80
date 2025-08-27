        ;; convert unsigned int to packed bcd (3 bytes)
        ;; shifts 16-bit value and daa-accumulates into c,d,e (low..high)
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2020-2021 sergey belyashov
		
        .module __uitobcd                          ; module name
        .optsdcc -mz80 sdcccall(1)                 ; sdcc z80, sdcccall(1) abi
        .area   _CODE                              ; code segment

        .globl  ___uitobcd                         ; export symbol

        ;; ___uitobcd
        ;; inputs (sdcccall):
        ;;   hl = value (unsigned 16-bit)
        ;;   de = pointer to bcd[3]
        ;; outputs:
        ;;   stores 3 bcd bytes to *de (order: ones, tens, hundreds)
        ;; clobbers:
        ;;   a, b, c, d, e, h, l, f
        ;; notes:
        ;;   double dabble via daa over 16 shifts; small fast path when h=0
___uitobcd:
        push    de                                 ; save bcd pointer
        ld      bc, #0x1000                        ; b = 16 shift count, c = 0
        ld      d, c                               ; d = 0 (bcd mid)
        ld      e, c                               ; e = 0 (bcd low)

        ;; --- begin speed optimization -------------------------------------
        ld      a, h                               ; check if high byte is zero
        or      a, a                               ; z => value fits in 8 bits
        jr      nz, 100$                           ; skip if not zero
        ld      h, l                               ; compact: put low byte in h
        srl     b                                  ; halve shift count: 16 -> 8
        ;; --- end speed optimization ---------------------------------------

        ;; hl = binary value (h carries the active byte)
        ;; cde = future bcd value (low..high), b = bit count
100$:
        add     hl, hl                             ; shift value left
        ld      a, e                               ; bcd low nibble
        adc     a, a                               ; add next bit with carry
        daa                                         ; adjust to bcd
        ld      e, a                               ; store back

        ld      a, d                               ; bcd middle
        adc     a, a
        daa
        ld      d, a

        ld      a, c                               ; bcd high
        adc     a, a
        daa
        ld      c, a
        djnz    100$                               ; loop for all bits

        pop     hl                                 ; hl = bcd pointer
        ld      (hl), e                            ; store ones
        inc     hl
        ld      (hl), d                            ; store tens
        inc     hl
        ld      (hl), c                            ; store hundreds
        ret                                         ; done
