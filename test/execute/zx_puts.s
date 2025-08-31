        ;; zx_puts: print zero-terminated string
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module zx_puts
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  _zx_puts
        .globl  _zx_putc

        ;; _zx_puts(const char* s)
        ;; inputs: (stack) s
        ;; clobbers: af, hl
_zx_puts:
        pop     hl              ; return
        pop     de              ; DE <- s
        push    de
        push    hl
        ex      de,hl           ; HL = s
.next:
        ld      a,(hl)
        or      a
        jr      z,.done
        push    hl
        push    af
        call    _zx_putc
        pop     af
        pop     hl
        inc     hl
        jr      .next
.done:
        ret
