        ;; multiplication shims for signed/unsigned 8×8→16 bit
        ;; prepares operands in bc and de, then tail-calls __mul16
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2017-2021 philipp klaus krause
        ;; copyright (c) 2026 tomaz stih

        .module mulchar                            ; module name
        .optsdcc -mz80 sdcccall(1)
        .area   _CODE                              ; code segment

        .globl  __mulsuchar                        ; export symbols
        .globl  __muluschar
        .globl  __mulschar
        .globl  __mul16                            ; imported

        ;; __muluschar
        ;; inputs:  a = unsigned lhs, l = signed rhs
        ;; outputs: de = 16-bit product (via __mul16)
        ;; clobbers: a, b, c, d, e, f; plus any clobbers from __mul16
        ;; notes: builds bc unsigned, de signed
__muluschar:
        ld      e, a                               ; e = lhs (unsigned)
        ld      c, l                               ; c = rhs (signed)
        ld      b, #0                              ; bc = zero-extended rhs? (see below)
        jr      .signext_e                         ; sign-extend e into d

        ;; __mulsuchar
        ;; inputs:  a = signed lhs, l = unsigned rhs
        ;; outputs: de = 16-bit product (via __mul16)
        ;; clobbers: a, b, c, d, e, f; plus any clobbers from __mul16
        ;; notes: builds bc signed, de unsigned
__mulsuchar:
        ld      c, a                               ; c = lhs (signed)
        ld      b, #0                              ; b filled by sign extension below
        ld      e, l                               ; e = rhs (unsigned)
        jr      .signext_e                         ; sign-extend e into d (d becomes 0)

        ;; __mulschar
        ;; inputs:  a = signed lhs, l = signed rhs
        ;; outputs: de = 16-bit product (via __mul16)
        ;; clobbers: a, b, c, d, e, f; plus any clobbers from __mul16
        ;; notes: sign-extends both operands into bc and de
__mulschar:
        ld      e, l                               ; e = rhs (signed)
        ld      c, a                               ; c = lhs (signed)

        ;; sign-extend c into b
        bit     7, c
        sbc     a, a                               ; a = 00/ff from carry (carry set iff bit7=1)
        ld      b, a

.signext_e:
        ;; sign-extend e into d
        bit     7, e
        sbc     a, a                               ; a = 00/ff
        ld      d, a

        ;; tail-call: (bc) × (de) -> de (low 16 bits)
        jp      __mul16