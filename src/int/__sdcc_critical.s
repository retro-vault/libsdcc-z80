        ;; enter critical section with previous iffy state encoded in flags
        ;; disables interrupts and returns with p/v flag = 1 if interrupts
        ;; were enabled on entry, or p/v = 0 if they were already disabled
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2020 sergey belyashov
		
        .module __sdcc_critical                    ; module name
        .area   _CODE                              ; code segment

        .globl  ___sdcc_critical_enter             ; export symbol

        ;; ___sdcc_critical_enter
        ;; inputs:  none
        ;; outputs: interrupts disabled on return;
        ;;          a = 0; p/v flag = 1 if ints were enabled on entry,
        ;;          p/v flag = 0 if ints were disabled on entry
        ;; clobbers: a, f, i; touches sp, preserves all other regs
        ;; notes: nmOS z80 compatible; must not be placed at 0x0000..0x00ff
___sdcc_critical_enter:
        xor     a                                  ; a = 0 (clear), also z=1
        push    af                                 ; dummy push to keep stack flow
        pop     af                                 ; and restore
        ld      a, i                               ; load i; pe parity mirrors iff2
        di                                         ; disable interrupts now
        ret     pe                                 ; if iff2 was 1 -> return, p/v=1

        dec     sp                                 ; adjust return address on stack
        dec     sp                                 ; (matches early return path)
        pop     af                                 ; retrieve saved flags into af
        or      a                                  ; set flags from a (z unchanged)
        jr      nz, 00100$                         ; if nz, take "interrupts enabled" path

        ; interrupts were disabled on entry
        sub     a, a                               ; a = 0, force p/v = 0
        ret

00100$:
        ; interrupts were enabled on entry
        xor     a                                  ; a = 0, force p/v = 1
        ret
