        ;; zx_putc: output character via ZX ROM RST 0x10 (CH-OUT)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module zx_putc
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  _zx_putc

        ;; _zx_putc(char ch)
        ;; inputs: (stack) ch (promoted to int; low byte is the character)
        ;; clobbers: af, (temporarily IY; preserved on return)
_zx_putc:
        pop     hl              ; return
        pop     de              ; E = ch
        push    de
        push    hl

        ld      a,e
        push    iy
        ld      iy,#0x5C3A      ; ensure ROM sees correct system vars base
        rst     0x10            ; CH-OUT: prints A to current output stream
        pop     iy
        ret
