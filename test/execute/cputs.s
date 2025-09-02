        ;; print zero-terminated string via zx rom ch-out
        ;; maps '\n' to carriage return (0x0d)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module cputs                             ; module name
        .optsdcc -mz80 sdcccall(1)
        .area   _CODE                             ; code segment

        .globl  _cputs                            ; export symbols
        .globl  _cputc

        ;; _cputs
        ;; inputs:  hl = s
        ;; outputs: none
        ;; clobbers: a, f, iy
_cputs::
.next:
        ld      a, (hl)                           ; load next char
        or      a
        jr      z, .done                          ; stop on nul
        cp      #0x0a                             ; newline?
        jr      nz, .print
        ld      a, #0x0d                          ; map to cr

.print:
        push    iy                                ; preserve iy (rom sysvars)
        ld      iy, #0x5c3a                       ; system variables base
        rst     0x10                              ; ch-out: prints a
        pop     iy

        inc     hl
        jr      .next

.done:
        ret
