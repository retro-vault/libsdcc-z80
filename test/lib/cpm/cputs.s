        ;; cputs.s - CP/M string output via BDOS function 2
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module cputs
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  _cputs

        ;; _cputs(const char *s)
        ;; sdcccall(1): 16-bit pointer in HL
        ;; Outputs each character via BDOS function 2.
        ;; BDOS may clobber HL so it is saved/restored around each call.
_cputs:
.loop:
        ld      a,(hl)
        or      a
        ret     z               ;; null terminator: done
        ld      e,a             ;; char for BDOS
        push    hl              ;; save string pointer (BDOS clobbers HL)
        ld      c,#0x02         ;; BDOS function 2: console output
        call    5
        pop     hl              ;; restore pointer
        inc     hl              ;; advance to next char
        jr      .loop
