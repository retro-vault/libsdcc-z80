        .module ulong2fs
        .optsdcc -mz80 sdcccall(1)

        .area   _CODE

        .globl  ___ulong2fs
___ulong2fs:
        ex      de,hl                   ;; HL = low, DE = high
        ld      b,d
        ld      c,e                     ;; BC = high word

        ;; zero?
        ld      a,b
        or      c
        or      h
        or      l
        jr      nz, .nonzero
        xor     a
        ld      h,a
        ld      l,a
        ld      d,a
        ld      e,a
        ret

.nonzero:
        ld      e,#0x00                 ;; shift count
.norm:
        bit     7,b
        jr      nz, .norm_done
        add     hl,hl
        rl      c
        rl      b
        inc     e
        jr      .norm
.norm_done:
        ld      a,#158
        sub     e
        ld      d,a                     ;; D = exponent

        ;; rounding uses discarded byte L; kept bytes are B:C:H
        ld      a,l
        cp      #0x80
        jr      c, .rounded
        jr      nz, .round_up
        ld      a,h
        and     #0x01
        jr      z, .rounded
.round_up:
        inc     h
        jr      nz, .rounded
        inc     c
        jr      nz, .rounded
        inc     b
        jr      nz, .rounded
        ld      b,#0x80
        xor     a
        ld      c,a
        ld      h,a
        inc     d

.rounded:
        ;; save byte3 (mantissa low byte) before packing overwrites regs
        ld      e,h                     ;; E = byte3

        ;; pack exponent into byte0/byte1 (sign=0)
        ld      a,d
        srl     a                       ;; A = exp>>1, carry = exp&1
        ld      h,a                     ;; H = byte0

        ld      a,b
        and     #0x7F
        jr      nc, .no_explsb
        or      #0x80
.no_explsb:
        ld      l,a                     ;; L = byte1

        ;; low word bytes
        ld      d,c                     ;; D = byte2
        ;; E already = byte3

        ret
