        ;; memory move with overlap handling (like standard memmove)
        ;; copies n bytes from src to dst, safely supporting overlap
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2008-2021 philipp klaus krause, marco bodrato
		
        .module memmove                           ; module name
        .optsdcc -mz80 sdcccall(1)                ; sdcc z80, sdcccall(1) abi
        .area   _CODE                             ; code segment

        .globl  _memmove                          ; export symbol

        ;; _memmove
        ;; inputs (sdcccall convention):
        ;;   hl = destination pointer
        ;;   de = source pointer
        ;;   bc = length
        ;; outputs:
        ;;   de = original destination (returned to caller)
        ;; clobbers: a, bc, de, hl, iy, f
        ;; notes: decides copy direction depending on overlap, then
        ;;        uses ldir (forward) or lddr (backward)
_memmove:
        pop     iy                               ; return address to iy
        pop     bc                               ; bc = length
        ld      a, c                             ; test length
        or      a, b                             ; z if bc == 0
        ex      de, hl                           ; swap hl <-> de
        jr      z, end                           ; if zero length, done
        ex      de, hl                           ; restore hl=dst, de=src
        push    hl                               ; save dst on stack
        sbc     hl, de                           ; hl - de (carry unchanged)
        add     hl, de                           ; restore hl, carry preserved
        jr      c, memmove_up                    ; if dst<src, copy upwards

memmove_down:
        dec     bc                               ; adjust bc for block end
        add     hl, bc                           ; hl = dst+len-1
        ex      de, hl                           ; de = dst+len-1, hl = src
        add     hl, bc                           ; hl = src+len-1
        inc     bc                               ; restore bc
        lddr                                    ; copy backwards
        pop     de                               ; restore original dst
end:
        jp      (iy)                             ; return

memmove_up:
        ex      de, hl                           ; swap: hl = src, de = dst
        ldir                                    ; copy forwards
        pop     de                               ; restore original dst
        jp      (iy)                             ; return
