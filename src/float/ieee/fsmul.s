        .module fsmul
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE
        .globl  ___fsmul

___fsmul::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; (optional) if you allocate locals in the real mul, do it here.
        ;; for now, do nothing and return 0.0f.

        xor     a
        ld      e,a
        ld      d,a
        ld      l,a
        ld      h,a

.ret_cleanup:
        ld      sp,ix
        pop     ix
        pop     bc
        pop     af
        pop     af
        push    bc
        ret
