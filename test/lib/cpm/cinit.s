        ;; cinit.s - CP/M console init (no-op: no screen to initialise)
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2025 tomaz stih

        .module cinit
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  _cinit

_cinit:
        ret
