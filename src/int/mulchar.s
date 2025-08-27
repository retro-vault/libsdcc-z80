        ;; multiplication shims for signed/unsigned 8×8→16 bit
        ;; prepares operands in bc and de, then calls __mul16
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2017-2021 philipp klaus krause
        
        .module mulchar                          ; module name
        .optsdcc -mz80 sdcccall(1)               ; sdcc z80, sdcccall(1) abi
        .area   _CODE                            ; code segment

        .globl  __mulsuchar                      ; export symbols
        .globl  __muluschar
        .globl  __mulschar

        ;; __muluschar
        ;; inputs:  a = unsigned lhs, l = signed rhs
        ;; outputs: hl = 16-bit product (via __mul16)
        ;; clobbers: a, b, c, d, e, f; plus any clobbers from __mul16
        ;; notes: builds bc and de as signed 16-bit operands
__muluschar:
        ld      e, a                             ; e = a (temp reuse below)
        ld      c, l                             ; c = l (signed factor)
        ld      b, #0                            ; b = 0 (zero-extend unsigned)
        jr      signexte                         ; go sign-extend e into d

        ;; __mulsuchar
        ;; inputs:  a = signed lhs, l = unsigned rhs
        ;; outputs: hl = 16-bit product (via __mul16)
        ;; clobbers: a, b, c, d, e, f; plus any clobbers from __mul16
        ;; notes: builds bc signed, de unsigned
__mulsuchar:
        ld      c, a                             ; c = a (signed factor)
        ld      b, #0                            ; b = 0 for now
        ld      e, l                             ; e = l (unsigned factor)
        jr      signexte                         ; shared sign-extension path

        ;; __mulschar
        ;; inputs:  a = signed lhs, l = signed rhs
        ;; outputs: hl = 16-bit product (via __mul16)
        ;; clobbers: a, b, c, d, e, f; plus any clobbers from __mul16
        ;; notes: sign-extends both operands into bc and de
__mulschar:
        ld      e, l                             ; e = l (right factor)
        ld      c, a                             ; c = a (left factor)
        rla                                      ; carry = sign(a)
        sbc     a, a                             ; a = 00/ff by sign(a)
        ld      b, a                             ; b = sign(a)
signexte:
        ld      a, e                             ; a = e for sign test
        rla                                      ; carry = sign(e)
        sbc     a, a                             ; a = 00/ff by sign(e)
        ld      d, a                             ; d = sign(e)
        jp      __mul16                          ; (bc) × (de) → hl
