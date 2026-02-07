        ;; unsigned modulus helpers for 8-bit and 16-bit integers
        ;; calls unsigned divide helpers and returns the remainder
        ;;
        ;; code from sdcc project
        ;;
        ;; gpl-2.0-or-later (see: LICENSE)
        ;; copyright (c) 2009-2010 philipp klaus krause
		
        .module modunsigned                      ; module name
        .optsdcc -mz80 sdcccall(1)
        
        .area   _CODE                            ; code segment

        .globl  __moduchar                       ; export symbols
        .globl  __moduint

        ;; __moduchar
        ;; inputs:  a = dividend (8-bit), l = divisor (8-bit)
        ;; outputs: l = dividend % divisor (8-bit remainder)
        ;; clobbers: a, d, e, h, l, f; uses __divu8
        ;; notes: arranges (l<-a, e<-orig l), __divu8 yields q in l, r in e;
        ;;        swap de,hl to return r in l
__moduchar:
        ld      e, l                             ; e = divisor (orig l)
        ld      l, a                             ; l = dividend (from a)
        call    __divu8                          ; unsigned divide 8-bit
        ex      de, hl                           ; r in e -> l for return
        ret                                      ; return remainder in l

        ;; __moduint
        ;; inputs:  hl = dividend (16-bit), de = divisor (16-bit)
        ;; outputs: hl = dividend % divisor (16-bit remainder)
        ;; clobbers: a, b, c, d, e, h, l, f; uses __divu16
        ;; notes: __divu16 yields q in hl, r in de; swap to return r in hl
__moduint:
        call    __divu16                         ; unsigned divide 16-bit
        ex      de, hl                           ; place remainder into hl
        ret                                      ; return remainder in hl
