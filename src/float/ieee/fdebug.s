;;
;; float debug scratch variables for ieee helpers
;;
;; purpose:
;;     global scratch storage for debugging float helpers. helpers can store
;;     intermediate bytes/words here, and the c test harness can print them
;;     after a test fails.
;;
;; exported symbols:
;;     _fdebug_b1.._fdebug_b4   (1 byte each)
;;     _fdebug_w1.._fdebug_w4   (2 bytes each, little-endian)
;;
;; debug helper routines (preserve ALL regs):
;;     _fdebug_store_a_b1..b4
;;     _fdebug_store_bc_w1..w4
;;     _fdebug_store_de_w1..w4
;;     _fdebug_store_hl_w1..w4
;;
;; gpl-2.0-or-later (see: LICENSE)
;; (c) 2025 tomaz stih
;;

        .module fdebug
        .optsdcc -mz80 sdcccall(1)

        .area   _DATA

        .globl  _fdebug_b1
        .globl  _fdebug_b2
        .globl  _fdebug_b3
        .globl  _fdebug_b4
        .globl  _fdebug_w1
        .globl  _fdebug_w2
        .globl  _fdebug_w3
        .globl  _fdebug_w4

_fdebug_b1:
        .ds     1
_fdebug_b2:
        .ds     1
_fdebug_b3:
        .ds     1
_fdebug_b4:
        .ds     1

_fdebug_w1:
        .ds     2
_fdebug_w2:
        .ds     2
_fdebug_w3:
        .ds     2
_fdebug_w4:
        .ds     2

        .area   _CODE

        .globl  _fdebug_store_a_b1
        .globl  _fdebug_store_a_b2
        .globl  _fdebug_store_a_b3
        .globl  _fdebug_store_a_b4

        .globl  _fdebug_store_bc_w1
        .globl  _fdebug_store_bc_w2
        .globl  _fdebug_store_bc_w3
        .globl  _fdebug_store_bc_w4

        .globl  _fdebug_store_de_w1
        .globl  _fdebug_store_de_w2
        .globl  _fdebug_store_de_w3
        .globl  _fdebug_store_de_w4

        .globl  _fdebug_store_hl_w1
        .globl  _fdebug_store_hl_w2
        .globl  _fdebug_store_hl_w3
        .globl  _fdebug_store_hl_w4


;; ------------------------------------------------------------
;; store A -> bN
;; ------------------------------------------------------------

_fdebug_store_a_b1::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_b1),a
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_a_b2::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_b2),a
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_a_b3::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_b3),a
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_a_b4::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_b4),a
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret


;; ------------------------------------------------------------
;; store BC/DE/HL -> wN (little-endian)
;; ------------------------------------------------------------

_fdebug_store_bc_w1::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w1),bc
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_bc_w2::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w2),bc
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_bc_w3::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w3),bc
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_bc_w4::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w4),bc
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret


_fdebug_store_de_w1::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w1),de
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_de_w2::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w2),de
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_de_w3::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w3),de
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_de_w4::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w4),de
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret


_fdebug_store_hl_w1::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w1),hl
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_hl_w2::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w2),hl
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_hl_w3::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w3),hl
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

_fdebug_store_hl_w4::
        push    af
        push    bc
        push    de
        push    hl
        ld      (_fdebug_w4),hl
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret
