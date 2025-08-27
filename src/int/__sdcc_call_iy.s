        ;; tail-call helper that jumps via iy (function pointer thunk)
        ;; uses jp (iy) to transfer control to target address in iy
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2011 maarten brock, 2015 philipp klaus krause
		
        .module crtcall                            ; module name
        .optsdcc -mz80 sdcccall(1)                 ; sdcc z80, sdcccall(1) abi
        .area   _CODE                              ; code segment

        .globl  ___sdcc_call_iy                    ; export symbol

        ;; ___sdcc_call_iy
        ;; inputs:  iy = target address (function pointer)
        ;; outputs: none (control transfers to *iy)
        ;; clobbers: pc only (no registers modified)
___sdcc_call_iy:
        jp      (iy)                               ; jump indirectly via iy
