        ;; unsigned 32-bit modulus helper (long)
        ;; calls __divulong and returns remainder
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module modulong                           ; module name
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE                              ; code segment

        .globl  __modulong                         ; export symbol
        .globl  __divulong                         ; imported core
        .globl  __get_remainder_ulong              ; imported helper

        ;; __modulong
        ;; inputs:  de:hl = dividend (u32), 4(ix)..7(ix) = divisor (u32)
        ;; outputs: de:hl = remainder (u32)
        ;; clobbers: per __divulong / helper
__modulong:
        call    __divulong                         ; compute quotient + store r
        jp      __get_remainder_ulong              ; fetch r into de:hl
