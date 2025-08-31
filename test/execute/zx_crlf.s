        ;; zx_crlf: print CR (newline on Spectrum)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module zx_crlf
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  _zx_crlf
        .globl  _zx_putc

_zx_crlf:
        ld      e,#13
        jp      _zx_putc
