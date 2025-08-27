        ;; signed modulus helper for 32-bit integers (long)
        ;; calls 32-bit signed divide core and returns the remainder
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module modslong                           ; module name
        .optsdcc -mz80 sdcccall(1)


        .area   _CODE                              ; code segment

        .globl  __modslong                         ; export symbol
        .globl  __divslong                         ; imported divide core
        .globl  __get_remainder_long               ; imported remainder helper

        ;; __modslong
        ;; inputs:  de:hl = dividend (signed 32-bit, de high, hl low)
        ;;          4(ix)..7(ix) = divisor (signed 32-bit, little endian)
        ;; outputs: de:hl = remainder (signed 32-bit)
        ;; clobbers: a, b, c, d, e, h, l, ix, f; per __divslong/__get_remainder_long
        ;; notes: mirrors 8/16-bit pattern: divide, then normalize remainder
__modslong:
        call    __divslong                         ; compute q, store unsigned r
        jp      __get_remainder_long               ; fix sign, return r in de:hl
