![status.badge] [![language.badge]][language.url] [![standard.badge]][standard.url] [![license.badge]][license.url]

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
- Supports `int`, `long`, `long long`, `float`
- Full coverage of arithmetic, comparisons, shifts, and type conversions
- Docker-based build (no local toolchain required)
- Comprehensive ZX Spectrum automated tests

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
│   └── float/
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
| `src/int/`               | Integer arithmetic and helper routines. |
| `src/float/`             | Floating-point arithmetic and helper routines. |
| `test/`                  | ZX Spectrum test suite and bare-metal SDCC examples. |
| `test/lib/`              | ZX Spectrum–specific support code and `crt0`. |
| `test/include/`          | Header files used by tests. |
| `test/src/`              | Test sources. |
| `test/src/compile/`      | Compile-only tests (symbol resolution, no binaries produced). |
| `test/src/execute/`      | Runtime ZX Spectrum tests for integer and floating-point operations. |

> **Note**  
> All builds use the Docker image  
> [`wischner/sdcc-z80-zx-spectrum:latest`](https://hub.docker.com/r/wischner/sdcc-z80-zx-spectrum)

## How do I leave feedback?

Use the GitHub Issues at the top of this page.

[language.url]:   https://en.wikipedia.org/wiki/ANSI_C
[language.badge]: https://img.shields.io/badge/language-C-blue.svg

[standard.url]:   https://en.wikipedia.org/wiki/C11_(C_standard_revision)
[standard.badge]: https://img.shields.io/badge/standard-C11-blue.svg

[license.url]:    https://github.com/tstih/nice/blob/master/LICENSE
[license.badge]:  https://img.shields.io/badge/license-MIT-blue.svg

[status.badge]:  https://img.shields.io/badge/status-stable-dkgreen.svg
