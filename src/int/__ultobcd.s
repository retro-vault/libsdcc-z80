        ;; convert unsigned long to packed bcd (5 bytes)
        ;; shifts the 32-bit value bit-by-bit and daa-accumulates into c,d,e,h,l
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2020-2021 sergey belyashov
		
        .module __ultobcd                           ; module name
        .optsdcc -mz80 sdcccall(1)                  ; sdcc z80, sdcccall(1) abi
        .area   _CODE                               ; code segment

        .globl  ___ultobcd                          ; export symbol

        ;; ___ultobcd
        ;; inputs (sdcccall):
        ;;   stack: (ix-4..ix-1) = v (u32, little endian)
        ;;           top-of-stack = bcd pointer (u8[5]); popped late into hl
        ;; outputs:
        ;;   stores 5 bcd bytes to *bcd (order: ones, tens, hundreds, thousands,
        ;;   ten-thousands), no return value
        ;; clobbers:
        ;;   a, b, c, d, e, h, l, ix, f; uses sp temporaries, preserves none
        ;; notes:
        ;;   uses double dabble (shift-add-3 via daa) over 32 bits. a 32→20 bcd
        ;;   conversion fits in c,d,e,h,l (5 bytes). includes small fast-paths.
___ultobcd:
        pop     af                                  ; save return address
        pop     bc                                  ; pop bcd pointer
        push    af                                  ; restore return to stack
        push    bc                                  ; keep bcd pointer on stack
        push    ix                                  ; save ix
        ld      ix, #0                              ; ix <- sp (frame base)
        add     ix, sp                              ; ix = sp
        ; ld     sp, ix                              ; sp already equals ix

        ld      bc, #0x2000                         ; b = bit count guess, c unused

        ;; --- begin speed optimization -------------------------------------
        ld      a, l                                ; test high 16 bits zero?
        or      a, h                                ; z if hl == 0
        jr      nz, 101$                            ; skip if not zero
        ; high 2 bytes are zero
        ld      b, #0x10                            ; only 16 shifts needed
        ex      de, hl                              ; move low 16 into hl
101$:
        ld      a, h                                ; test high 8 bits zero?
        or      a, a                                ; z if h == 0
        jr      nz, 102$                            ; skip if not zero
        ; high byte is zero
        ld      h, l                                ; compact 24→16 for shifts
        ld      l, d
        ld      d, e
        ld      a, #-8                              ; reduce shift count by 8
        add     a, b
        ld      b, a
102$:
        push    hl                                  ; save compacted low word
        push    de                                  ; save the other word
        ;; --- end speed optimization ---------------------------------------

        ld      hl, #0x0000                         ; init bcd accum: hl = 0000
        ld      e, l                                ; e = 00
        ld      d, h                                ; d = 00
        ; (ix-4)..(ix-1) = binary value
        ; c,d,e,h,l = future bcd (low..high)
        ; b = bits count (starts from 32 or reduced by fast path)

103$:
        sla     (ix-4)                              ; shift value left through
        rl      (ix-3)                              ;  its 4 bytes on stack
        rl      (ix-2)
        rl      (ix-1)

        ld      a, l                                ; add lowest bcd byte + carry
        adc     a, a
        daa                                         ; adjust to bcd
        ld      l, a

        ld      a, h                                ; next bcd byte
        adc     a, a
        daa
        ld      h, a

        ld      a, e                                ; next
        adc     a, a
        daa
        ld      e, a

        ld      a, d                                ; next
        adc     a, a
        daa
        ld      d, a

        ld      a, c                                ; highest bcd byte
        adc     a, a
        daa
        ld      c, a

        djnz    103$                                ; process all bits

        ld      b, l                                ; pack result for store
        ld      a, h
        ld      sp, ix                              ; tear down frame
        pop     ix                                  ; restore ix
        pop     hl                                  ; hl = bcd pointer

        ld      (hl), b                             ; *bcd++ = ones
        inc     hl
        ld      (hl), a                             ; tens
        inc     hl
        ld      (hl), e                             ; hundreds
        inc     hl
        ld      (hl), d                             ; thousands
        inc     hl
        ld      (hl), c                             ; ten-thousands

        ret                                         ; done
