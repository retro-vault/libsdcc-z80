        ;; tail-call helper that jumps via hl (function pointer thunk)
        ;; uses jp (hl) to transfer control to target address in hl
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2011 maarten brock
		
        .module crtcall                            ; module name
        .optsdcc -mz80 sdcccall(1)                 ; sdcc z80, sdcccall(1) abi
        .area   _CODE                              ; code segment

        .globl  ___sdcc_call_hl                    ; export symbol

        ;; ___sdcc_call_hl
        ;; inputs:  hl = target address (function pointer)
        ;; outputs: none (control transfers to *hl)
        ;; clobbers: pc only (no registers modified)
___sdcc_call_hl:
        jp      (hl)                               ; jump indirectly via hl
