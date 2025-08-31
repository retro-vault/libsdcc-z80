        ;; minimal crt0 for ZX Spectrum 48K (SDCC z80, sdcccall(1))
        ;; load at 32768 (0x8000):
        ;;   CLEAR 32767: LOAD "" CODE: RANDOMIZE USR 32768
        ;; sets a private stack, calls _main, returns to BASIC with RET (BC = 0)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module crt0_zx
        .optsdcc -mz80 sdcccall(1)

        .globl  _main

        .area   _CODE

_start:
        ld      sp,#__STACK

        ld      iy,#0x5C3A      ; set IY initially (ok if C changes later)
        ld      a,#2
        call    0x1601          ; CHAN-OPEN "S" (screen)
        call    _main
        xor     a
        ld      b,a
        ld      c,a
        ret


        xor     a
        ld      b,a
        ld      c,a
        ret

        .area   _DATA
__STACK:
        .ds     1024            ; 1 KB private stack

        .area   _BSS
        .ds     1               ; keep area non-empty
