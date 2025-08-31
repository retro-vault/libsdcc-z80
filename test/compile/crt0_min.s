; crt0_min.s — tiny SDCC/Z80 startup
    .module crt0_min
    .globl  _main

    .area   _CODE
__start:
    call    _main
halt:
    jp      halt