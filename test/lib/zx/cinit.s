        ;; init channels (for display)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih
        
        .module cinit
        .optsdcc -mz80 sdcccall(1)

        .globl  _cinit

        .area   _CODE
_cinit:
        ld      iy,#0x5C3A      ; set IY initially (ok if C changes later)
        ld      a,#2
        call    0x1601          ; CHAN-OPEN "S" (screen)
        ret