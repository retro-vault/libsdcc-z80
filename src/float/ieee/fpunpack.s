        ;; shared float unpack helpers for sdcc z80
        ;;
        ;; expects an IX frame with:
        ;;   -1(ix) = a3, -2(ix) = a2
        ;;    7(ix) = b3,  6(ix) = b2
        ;;
        ;; outputs:
        ;;   -5(ix) = sign(a) xor sign(b), masked with 0x80
        ;;   C      = biased exponent of a
        ;;   B      = biased exponent of b
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2026 tomaz stih

        .module fpunpack
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE
        .globl  __fp_unpack_sign_exps

__fp_unpack_sign_exps:
        ;; result sign
        ld      a,-1(ix)
        xor     7(ix)
        and     #0x80
        ld      -5(ix),a

        ;; exponent of A -> C
        ld      a,-1(ix)
        and     #0x7F
        rlca
        ld      c,a
        bit     7,-2(ix)
        jr      z,.ea_done
        set     0,c
.ea_done:
        ;; exponent of B -> B
        ld      a,7(ix)
        and     #0x7F
        rlca
        ld      b,a
        bit     7,6(ix)
        jr      z,.eb_done
        set     0,b
.eb_done:
        ret
