        ;; signed/unsigned mixed modulus helpers (8-bit × 8-bit)
        ;; handles combinations of signed/unsigned dividend and divisor
        ;;
        ;; loosely based on code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2010-2021 philipp klaus krause
        ;; copyright (c) 2026 tomaz stih
		
        .module modmixed                          ; module name
        .optsdcc -mz80 sdcccall(1)

        .globl  __modsuchar                       ; export symbols
        .globl  __moduschar

        ;; __modsuchar
        ;; inputs:  a = signed dividend (8-bit), l = unsigned divisor (8-bit)
        ;; outputs: hl = remainder (signed 16-bit, low byte holds result)
        ;; clobbers: a, d, e, h, l, f; plus any clobbers from __div_signexte /
        ;;           __get_remainder
        ;; notes: build hl as signed-extended dividend, e = divisor,
        ;;        call __div_signexte to divide, then normalize remainder
__modsuchar:
        ld      e, l                              ; e = divisor (unsigned)
        ld      l, a                              ; l = dividend low
        ld      h, #0                             ; h = 0 (sign extended later)
        call    __div_signexte                    ; mixed signed/unsigned divide
        jp      __get_remainder                   ; finalize remainder in hl

        ;; __moduschar
        ;; inputs:  a = unsigned dividend (8-bit), l = signed divisor (8-bit)
        ;; outputs: hl = remainder (signed 16-bit, low byte holds result)
        ;; clobbers: a, d, e, h, l, f; plus any clobbers from __div16 /
        ;;           __get_remainder
        ;; notes: build hl as sign-extended divisor, de = unsigned dividend,
        ;;        perform signed divide, then normalize remainder
__moduschar:
        ld      e, l                              ; e = divisor (signed)
        ld      d, #0                             ; d = 0 (setup de pair)
        ld      l, a                              ; l = dividend low

        rlca                                      ; shift sign bit of a into carry
        sbc     a, a                              ; a = 0x00 or 0xff depending on sign
        ld      h, a                              ; h = sign extension of dividend

        call    __div16                           ; signed 16-bit divide
        jp      __get_remainder                   ; finalize remainder in hl
