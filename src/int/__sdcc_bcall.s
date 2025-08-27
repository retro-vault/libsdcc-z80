        ;; trampolines for banked function calls (generic)
        ;; switches banks via user-provided set_bank/get_bank and jumps
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2011 maarten brock,
        ;; 2015-2021 philipp klaus krause
		
        .module __sdcc_bcall                       ; module name
        .optsdcc -mz80 sdcccall(1)                 ; sdcc z80, sdcccall(1) abi
        .area   _CODE                              ; code segment

        .globl  ___sdcc_bcall                      ; export symbols
        .globl  ___sdcc_bcall_abc
        .globl  ___sdcc_bcall_ehl
        .globl  ___sdcc_bjump_abc
        .globl  ___sdcc_bjump_ehl
        .globl  set_bank                           ; provided by user
        .globl  get_bank                           ; provided by user

        ;; ___sdcc_bcall
        ;; inputs:  on stack after return addr:
        ;;          .dw function, .dw function_bank
        ;; outputs: a = bank number for jump helper, bc = function addr
        ;; clobbers: a, b, c, hl, f; preserves de, ix, iy
        ;; notes: legacy banking only; typical use:
        ;;        call ___sdcc_bcall ; .dw func ; .dw bank
___sdcc_bcall:
        ex      (sp), hl                           ; hl -> retaddr, retaddr -> hl
        ld      c, (hl)                            ; c = low(function)
        inc     hl                                 ; advance
        ld      b, (hl)                            ; b = high(function)
        inc     hl                                 ; advance
        ld      a, (hl)                            ; a = function_bank
        inc     hl                                 ; skip bank low (padding)
        inc     hl                                 ; now hl = original retaddr
        ex      (sp), hl                           ; restore retaddr to stack
                                                   ; (a=bank, bc=function)

        ;; ___sdcc_bcall_abc
        ;; inputs:  a = function_bank, bc = function (fastcall style)
        ;; outputs: jumps to function, returns with original bank restored
        ;; clobbers: a, h, l, f; preserves bc across trampoline push/pop
        ;; notes: calls user get_bank/set_bank
___sdcc_bcall_abc:
        push    hl                                 ; save hl
        ld      l, a                               ; l = desired bank
        call    get_bank                           ; a = current bank
        ld      h, a                               ; h = saved bank
        ld      a, l                               ; a = desired bank
        ex      (sp), hl                           ; [sp]=saved bank, hl=saved hl
        inc     sp                                 ; adjust for helper ret layout
        call    ___sdcc_bjump_abc                  ; bank switch + tail setup
        dec     sp                                 ; restore sp
        pop     af                                 ; a = saved bank
        jp      set_bank                           ; restore original bank

        ;; ___sdcc_bjump_abc
        ;; inputs:  a = desired bank, bc = function
        ;; outputs: returns into function with bank set
        ;; clobbers: a, f; pushes bc for ret-through jump
___sdcc_bjump_abc:
        call    set_bank                           ; switch to desired bank
        push    bc                                 ; push function address
        ret                                        ; return into function

        ;; ___sdcc_bcall_ehl
        ;; inputs:  e = function_bank, hl = function
        ;; outputs: jumps to function, returns with original bank restored
        ;; clobbers: a, b, c, d, e, h, l, f
        ;; notes: default trampoline variant
___sdcc_bcall_ehl:
        call    get_bank                           ; a = current bank
        push    af                                 ; save current bank
        inc     sp                                 ; adjust stack for helper
        call    ___sdcc_bjump_ehl                  ; switch and jump
        dec     sp                                 ; restore stack
        pop     bc                                 ; b:c = saved bank (from a)
        push    af                                 ; save a across set_bank
        ld      a, b                               ; a = saved bank
        call    set_bank                           ; restore original bank
        pop     af                                 ; restore a
        ret                                        ; back to caller

        ;; ___sdcc_bjump_ehl
        ;; inputs:  e = desired bank, hl = function
        ;; outputs: tail-jumps to function with bank set
        ;; clobbers: a, f
___sdcc_bjump_ehl:
        ld      a, e                               ; a = desired bank
        call    set_bank                           ; switch bank
        jp      (hl)                               ; jump to function
