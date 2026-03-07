        ;; cclear.s - CP/M console clear (no-op: no screen to clear)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module cclear
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  _cclear

_cclear:
        ret
