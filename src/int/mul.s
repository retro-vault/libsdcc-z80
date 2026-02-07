        ;; 16-bit multiply, speed-optimized
        ;; provides both __mulint (hl*de) and __mul16 (bc*de)
        ;;
        ;; algorithm:
        ;;   acc in hl
        ;;   multiplicand in de (shift left)
        ;;   multiplier in bc (shift right), early-out when bc==0
        ;; optional swap to make multiplier smaller -> fewer iterations
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright 2009-2010 philipp klaus krause
        ;; copytight 2026 tomaz stih

        .module mul
        .optsdcc -mz80 sdcccall(1)
        .area   _CODE

        .globl  __mulint
        .globl  __mul16

        ;; __mulint
        ;; inputs:  hl = multiplicand, de = multiplier
        ;; outputs: de = product low 16
        ;; clobbers: a, b, c, h, l, f
__mulint:
        ld      c, l
        ld      b, h
        jp      __mul16

        ;; __mul16
        ;; inputs:  bc = multiplicand, de = multiplier
        ;; outputs: de = product low 16
        ;; clobbers: a, b, c, h, l, f
__mul16:
        ;; quick zero checks
        ld      a, b
        or      a, c
        jr      z, .ret_zero                        ; if bc == 0

        ld      a, d
        or      a, e
        jr      z, .ret_zero                        ; if de == 0

        ;; make bc the smaller operand (as multiplier) if bc > de
        ;; compare bc - de (unsigned)
        ld      a, c
        sub     a, e
        ld      a, b
        sbc     a, d
        jr      c, .no_swap                         ; bc < de -> ok

        ;; swap bc <-> de
        ld      a, c
        ld      c, e
        ld      e, a
        ld      a, b
        ld      b, d
        ld      d, a

.no_swap:
        ;; acc = 0 in hl
        xor     a
        ld      h, a
        ld      l, a

.mul_loop:
        ;; if (bc & 1) acc += de
        bit     0, c
        jr      z, .skip_add
        add     hl, de
.skip_add:
        ;; de <<= 1  (faster than ex/add/ex)
        sla     e
        rl      d

        ;; bc >>= 1
        srl     b
        rr      c

        ;; early-out if bc == 0
        ld      a, b
        or      a, c
        jr      nz, .mul_loop

        ;; return: acc in hl -> de
        ex      de, hl
        ret

.ret_zero:
        xor     a
        ld      d, a
        ld      e, a
        ret