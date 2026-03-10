![status.badge] [![language.badge]][language.url] [![license.badge]][license.url]

# libsdcc-z80

## Table of contents

- [Introduction](#introduction)
- [Features](#features)
- [Building the Library](#building-the-library)
- [Running the Tests](#running-the-tests)
- [Output Files](#output-files)
- [Directory Structure](#directory-structure)
- [Feedback](#feedback)

## Introduction

**libsdcc-z80** is a bare-metal runtime library for *SDCC* targeting the *Z80*
processor. It is intended for builds that disable the standard SDCC runtime
with `--nostdlib`, `--nostdinc`, and `--no-std-crt0`.

When used in that mode, SDCC still emits calls to helper routines for integer
math, floating-point math, conversions, indirect calls, and other runtime glue.
This repository provides those helper routines as Z80 assembly so the linker
can resolve them without the stock SDCC runtime.

## Features

- 100% Z80 assembly runtime
- Integer, long, and float helper routines used by SDCC code generation
- Runtime support helpers such as indirect call entry points and banked-call glue
- Unified `DOCKER=on/off` build flow matching `libcpm3-z80`
- CP/M-based tests that can be compiled natively or built and run in Docker

## Building the Library

The top-level `Makefile` now follows the same parameter model as
`libcpm3-z80`.

### Commands

| Command | Description |
|---------|-------------|
| `make` | Build the library |
| `make test` | Build tests; when `DOCKER=on` also run them in RunCPM |
| `make clean` | Remove `build/` and `bin/` |

### Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `DOCKER` | `on`, `off` | `on` | `on` builds inside `wischner/sdcc-z80`. `off` builds natively and requires SDCC tools on `PATH`. |
| `BUILD_DIR` | path | `build/` | Intermediate build products. |
| `BIN_DIR` | path | `bin/` | Final outputs copied from the build. |

Examples:

```sh
make
make DOCKER=off
make DOCKER=off BUILD_DIR=out/build BIN_DIR=out/bin
```

## Running the Tests

```sh
make test
```

Behavior depends on `DOCKER`:

- `DOCKER=on` builds the library, builds the CP/M test binaries, builds the
  RunCPM test image if needed, and runs the tests.
- `DOCKER=off` builds the library and test binaries only. This is intended for
  local SDCC workflows where you want the `.com` outputs but not the emulator run.

Test results produced by the Docker flow are written to `bin/itest.txt` and
`bin/ftest.txt`.

## Output Files

All final outputs are placed in `bin/` (or `BIN_DIR` if overridden):

| File | Description |
|------|-------------|
| `libsdcc-z80.lib` | SDCC Z80 runtime helper library |
| `libcpm.lib` | CP/M support library used by the executable tests |
| `crt0cpm.rel` | CP/M CRT0 object used by the executable tests |
| `itest.com` | Integer runtime execution test |
| `ftest.com` | Floating-point runtime execution test |

The top-level build copies `libsdcc-z80.lib` from `BUILD_DIR` into `BIN_DIR`,
matching the `libcpm3-z80` packaging convention.

## Directory Structure

```text
.
├── Makefile
├── src/
│   ├── int/
│   ├── float/
│   └── runtime/
└── test/
    ├── Dockerfile.cpm
    ├── run_tests.sh
    ├── include/
    ├── lib/
    │   └── cpm/
    └── src/
        ├── compile/
        └── execute/
```

| Path | Description |
|------|-------------|
| `src/int/` | Integer helper routines used by SDCC |
| `src/float/` | IEEE-754 single-precision helper routines |
| `src/runtime/` | Non-arithmetic runtime helper entry points |
| `test/src/compile/` | Compile/link coverage tests |
| `test/src/execute/` | CP/M executable runtime tests |
| `test/lib/cpm/` | Minimal CP/M support code for executable tests |

## Feedback

Use the GitHub Issues at the top of this page.

[language.url]:   https://rosettacode.org/wiki/Category:Z80_Assembly
[language.badge]: https://img.shields.io/badge/language-Z80%20Assembly-blue.svg

[license.url]:    https://github.com/retro-vault/libsdcc-z80/blob/main/LICENSE
[license.badge]:  https://img.shields.io/badge/license-GPL2-blue.svg

[status.badge]:   https://img.shields.io/badge/status-stable-dkgreen.svg
