        ;; cputc.s - CP/M character output via BDOS function 2
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module cputc
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  _cputc

        ;; _cputc(char ch)
        ;; sdcccall(1): 8-bit arg in A
        ;; BDOS function 2: console output, char in E
_cputc:
        ld      e,a             ;; E = character
        ld      c,#0x02         ;; BDOS function 2: console output
        jp      5               ;; tail call to BDOS (returns to our caller)
