        ;; reverse a string in place (two-pointer swap from ends to middle)
        ;; starts at end-1 (before nul) and swaps with start while hl>=de
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2020-2021 sergey belyashov
		
        .module __strreverse                       ; module name
        .optsdcc -mz80 sdcccall(1)                 ; sdcc z80, sdcccall(1) abi
        .area   _CODE                              ; code segment

        .globl  ___strreverse                      ; export symbols
        .globl  ___strreverse_reg

        ;; ___strreverse
        ;; inputs:  hl = start, de = end (points to terminating nul)
        ;; outputs: none (string reversed in place)
        ;; clobbers: a, c, de, hl, f
        ;; notes: swaps hl<->de so the worker sees hl=end, de=start
___strreverse:
        ex      de, hl                             ; worker expects hl=end, de=start

        ;; ___strreverse_reg
        ;; inputs:  hl = end (points to terminating nul), de = start
        ;; outputs: none (in-place)
        ;; clobbers: a, c, de, hl, f
        ;; notes: uses sbc hl,de with carry=0 to compare, then restores
        ;;        hl by add hl,de before swapping bytes
___strreverse_reg:
        jr      110$                               ; jump to compare logic
100$:
        add     hl, de                             ; restore hl after sbc
        ld      a, (de)                            ; a = *de
        ld      c, (hl)                            ; c = *hl
        ld      (hl), a                            ; *hl = old *de
        ld      a, c                               ; a = old *hl
        ld      (de), a                            ; *de = old *hl
        inc     de                                 ; move start forward
110$:
        dec     hl                                 ; move end backward (skip nul)
        or      a, a                               ; clear carry for compare
        sbc     hl, de                             ; hl = hl - de (sets flags)
        jr      nc, 100$                           ; while (hl >= de) do swap
        ret                                        ; done
