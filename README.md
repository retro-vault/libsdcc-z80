![status.badge] [![language.badge]][language.url] [![license.badge]][license.url]

# libsdcc-z80

## introduction

**libsdcc-z80** is a bare-metal runtime library for the *SDCC* C compiler targeting
the *Z80* processor. It is intended for builds where the standard SDCC runtime is
disabled using `--nostdlib`, `--nostdinc`, and `--no-std-crt0`.

In this mode, SDCC does not provide startup code or runtime support. This is
commonly used when targeting custom or unsupported Z80 systems, or when writing
firmware or operating systems with full control over memory layout and startup.

The *Z80* processor lacks native support for many C language operations, such as
integer and floating-point arithmetic and certain type conversions. SDCC replaces
these operations with calls to helper functions, which are normally supplied by
the standard runtime.

**libsdcc-z80** provides these missing helper routines as optimized Z80 assembly.
The C source code remains unchanged, helper calls are generated automatically by
the compiler, and all symbols are resolved by the linker.

## features

- 100% Z80 assembly (zero C in the runtime)
- Optimized for speed
- Supports `int`, `long`, `float`
- Includes compiler runtime glue used by SDCC code generation
- Full coverage of arithmetic, comparisons, shifts, and type conversions
- Docker-based build (no local toolchain required)
- Comprehensive ZX Spectrum automated tests

## what is included

`libsdcc-z80` is split by compiler feature usage, not just by file type.

- `src/int/`
  - 8/16/32-bit integer helpers used when C emits runtime calls for:
    - multiply, divide, modulo
    - signed/unsigned mixed arithmetic
    - promotion/widening paths (for example 16x16 -> 32)
  - Compatibility alias symbols (`*_rrx_s`, `*_rrf_s`) are exported directly from implementation entry points.
- `src/float/`
  - IEEE-754 single-precision helpers used for:
    - `+`, `-`, `*`, `/` on `float`
    - float comparisons
    - int/long <-> float conversions
    - shared float pack/unpack/return helpers
- `src/runtime/`
  - SDCC runtime/platform helpers used by non-arithmetic codegen:
    - indirect calls (`___sdcc_call_hl`, `___sdcc_call_iy`) used by function-pointer calls
    - frame-entry helper (`___sdcc_enter_ix`) for shared prologue patterns
    - banked-call helpers (`___sdcc_bcall`, `___sdcc_bcall_ehl`)
    - critical-section helper symbol (`___sdcc_critical`) for compiler/runtime compatibility

# building

## using makefile

The project is built using `make` and runs entirely inside Docker. No local SDCC installation is required.

~~~sh
make          # build library and tests
make lib      # build library only
make clean
~~~

The library is placed in the `bin/` directory.

To integrate the build into another project, override the output directories using relative paths:

~~~sh
make BUILD_DIR=obj BIN_DIR=output
~~~

> **Note**  
> When custom output directories are used, the same variables must also be
> provided when cleaning:
>
> ~~~sh
> make BUILD_DIR=obj BIN_DIR=output clean
> ~~~

## directory structure

The project is split into a small runtime library and a ZX Spectrum–based test suite.  
All builds run inside Docker.

~~~text
.
├── Makefile
├── src/
│   ├── int/
│   ├── float/
│   └── runtime/
└── test/
    ├── lib/
    ├── include/
    └── src/
        ├── compile/
        └── execute/
~~~

| path                     | description |
|--------------------------|-------------|
| `Makefile`               | Top-level build entry point. Pulls the Docker image and delegates builds to subdirectories. |
| `src/`                   | `libsdcc-z80` runtime library (Z80 assembly only). |
| `src/int/`               | Integer helpers (`char`/`int`/`long` mul/div/mod, mixed signed/unsigned paths, widening helpers, legacy aliases). |
| `src/float/`             | IEEE-754 `float` helpers (arithmetics, comparisons, conversions, shared packing/unpacking routines). |
| `src/runtime/`           | SDCC runtime glue for indirect calls, frame entry, banked calls, and critical-section symbol compatibility. |
| `test/`                  | ZX Spectrum test suite and bare-metal SDCC examples. |
| `test/lib/`              | ZX Spectrum–specific support code and `crt0`. |
| `test/include/`          | Header files used by tests. |
| `test/src/`              | Test sources. |
| `test/src/compile/`      | Compile+link-only tests that verify SDCC-generated helper references resolve (no ZX runtime execution). |
| `test/src/execute/`      | Executed ZX Spectrum TAP tests validating runtime behavior for integer and floating-point operations. |

> **Note**  
> All builds use the Docker image  
> [`wischner/sdcc-z80-zx-spectrum:latest`](https://hub.docker.com/r/wischner/sdcc-z80-zx-spectrum)

## How do I leave feedback?

Use the GitHub Issues at the top of this page.

[language.url]:   https://rosettacode.org/wiki/Category:Z80_Assembly
[language.badge]: https://img.shields.io/badge/language-Z80%20Assembly-blue.svg

[license.url]:    https://github.com/retro-vault/libsdcc-z80/blob/main/LICENSE
[license.badge]:  https://img.shields.io/badge/license-GPL2-blue.svg

[status.badge]:  https://img.shields.io/badge/status-stable-dkgreen.svg
