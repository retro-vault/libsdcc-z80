        ;; float helper utilities for sdcc z80
        ;; dummy implementations of all float helpers so test_float.c will link.
        ;; includes utility helpers (.zero32/.zero16) that can be reused later.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module fp
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; __fp_zero32
        ;; inputs:  n/a
        ;; outputs: de:hl = 0x00000000
        ;; clobbers: af, de, hl
        .globl  __fp_zero32
__fp_zero32:
.zero32:
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

        ;; __fp_zero16
        ;; inputs:  n/a
        ;; outputs: hl = 0x0000
        ;; clobbers: af, hl
        .globl  __fp_zero16
__fp_zero16:
.zero16:
        xor     a
        ld      h,a
        ld      l,a
        ret

        ;; ___fsadd
        ;; inputs:  (stack) float a, float b
        ;; outputs: de:hl = a + b
        ;; clobbers: af, de, hl
        .globl  ___fsadd
___fsadd:
        jr      .zero32

        ;; ___fssub
        ;; inputs:  (stack) float a, float b
        ;; outputs: de:hl = a - b
        ;; clobbers: af, de, hl
        .globl  ___fssub
___fssub:
        jr      .zero32

        ;; ___fsmul
        ;; inputs:  (stack) float a, float b
        ;; outputs: de:hl = a * b
        ;; clobbers: af, de, hl
        .globl  ___fsmul
___fsmul:
        jr      .zero32

        ;; ___fsdiv
        ;; inputs:  (stack) float a, float b
        ;; outputs: de:hl = a / b
        ;; clobbers: af, de, hl
        .globl  ___fsdiv
___fsdiv:
        jr      .zero32

        ;; ___fseq
        ;; inputs:  (stack) float a, float b
        ;; outputs: hl = 1 if a == b, else 0
        ;; clobbers: af, hl
        .globl  ___fseq
___fseq:
        jr      .zero16

        ;; ___fslt
        ;; inputs:  (stack) float a, float b
        ;; outputs: hl = 1 if a < b, else 0
        ;; clobbers: af, hl
        .globl  ___fslt
___fslt:
        jr      .zero16

        ;; ___fs2schar
        ;; inputs:  (stack) float a
        ;; outputs: hl (L) = (signed char)a
        ;; clobbers: af, hl
        .globl  ___fs2schar
___fs2schar:
        jr      .zero16

        ;; ___fs2uchar
        ;; inputs:  (stack) float a
        ;; outputs: hl (L) = (unsigned char)a
        ;; clobbers: af, hl
        .globl  ___fs2uchar
___fs2uchar:
        jr      .zero16

        ;; ___fs2sint
        ;; inputs:  (stack) float a
        ;; outputs: hl = (int)a
        ;; clobbers: af, hl
        .globl  ___fs2sint
___fs2sint:
        jr      .zero16

        ;; ___fs2uint
        ;; inputs:  (stack) float a
        ;; outputs: hl = (unsigned int)a
        ;; clobbers: af, hl
        .globl  ___fs2uint
___fs2uint:
        jr      .zero16

        ;; ___fs2slong
        ;; inputs:  (stack) float a
        ;; outputs: de:hl = (long)a
        ;; clobbers: af, de, hl
        .globl  ___fs2slong
___fs2slong:
        jr      .zero32

        ;; ___fs2ulong
        ;; inputs:  (stack) float a
        ;; outputs: de:hl = (unsigned long)a
        ;; clobbers: af, de, hl
        .globl  ___fs2ulong
___fs2ulong:
        jr      .zero32

        ;; ___schar2fs
        ;; inputs:  (stack) signed char a  (promoted on push)
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, de, hl
        .globl  ___schar2fs
___schar2fs:
        jr      .zero32

        ;; ___uchar2fs
        ;; inputs:  (stack) unsigned char a (promoted on push)
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, de, hl
        .globl  ___uchar2fs
___uchar2fs:
        jr      .zero32

        ;; ___sint2fs
        ;; inputs:  (stack) int a
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, de, hl
        .globl  ___sint2fs
___sint2fs:
        jr      .zero32

        ;; ___uint2fs
        ;; inputs:  (stack) unsigned int a
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, de, hl
        .globl  ___uint2fs
___uint2fs:
        jr      .zero32

        ;; ___slong2fs
        ;; inputs:  (stack) long a  (de:hl on caller side)
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, de, hl
        .globl  ___slong2fs
___slong2fs:
        jr      .zero32

        ;; ___ulong2fs
        ;; inputs:  (stack) unsigned long a  (de:hl on caller side)
        ;; outputs: de:hl = (float)a
        ;; clobbers: af, de, hl
        .globl  ___ulong2fs
___ulong2fs:
        jr      .zero32
