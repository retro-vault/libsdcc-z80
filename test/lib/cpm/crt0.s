        ;; crt0.s - CP/M startup for libsdcc-z80 test harness
        ;;
        ;; CP/M loads .COM files at 0x0100 and jumps there.
        ;; 0x0000 = JP to BDOS warm boot, 0x0005 = BDOS entry.
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module crt0cpm
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        ;; set up local stack
        ld      sp,#__stack

        ;; SDCC global variable init (copy initialized data)
        call    gsinit

        ;; call main()
        call    _main

        ;; CP/M exit: BDOS function 0 = warm boot
        ld      c,#0x00
        jp      5

        ;; area ordering for linker
        .area   _GSINIT
        .area   _GSFINAL
        .area   _HOME
        .area   _INITIALIZER
        .area   _INITFINAL
        .area   _INITIALIZED
        .area   _DATA
        .area   _BSS
        .area   _HEAP

        .area   _GSINIT
gsinit:
        ld      de,#s__INITIALIZED
        ld      hl,#s__INITIALIZER
        ld      bc,#l__INITIALIZER
        ld      a,b
        or      a,c
        jr      z,.gsinit_done
        ldir
.gsinit_done:
        .area   _GSFINAL
        ret

        .area   _DATA
        .area   _BSS

        ;; 512-byte stack
        .ds     512
__stack:

        .area   _HEAP
__heap:
