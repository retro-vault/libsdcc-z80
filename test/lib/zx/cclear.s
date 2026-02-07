        ;; cclear: clear screen (via ROM routine)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module cclear
        .optsdcc -mz80 sdcccall(1)
        
        .area   _CODE

        .globl  _cclear

        ;; cclear()
        ;; inputs: -
        ;; clobbers: whatever ROM cls clobbers
_cclear:
        push    iy                      ; preserve IY: ROM uses sysvars at 0x5C3A
        ld      iy,#0x5c3a
        call    0x0DAF                  ; clear screen
        pop     iy
        ret