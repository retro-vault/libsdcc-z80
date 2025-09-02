        ;; cputc: output character via ZX ROM RST 0x10 (CH-OUT)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module cputc
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  _cputc

        ;; cputc(char ch)
        ;; inputs: (stack) ch (promoted to int; low byte is the character)
        ;; clobbers: af, (temporarily IY; preserved on return)
_cputc:
        push    iy                      ; preserve IY: ROM uses sysvars at 0x5C3A
        ld      iy,#0x5c3a
        rst     0x10                    ; CH-OUT
        pop     iy
        ret