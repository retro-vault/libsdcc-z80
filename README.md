![status.badge] [![language.badge]][language.url] [![standard.badge]][standard.url] [![license.badge]][license.url]

# The SDCC Z80 bare metal library

## What is **SDCC bare metal programming**?

It's when you use the *SDCC* C compiler without default startup code, header files, and libraries (using switches `--nostdlib`, `--nostdinc`, 
and `--no-std-crt0`). An example of this would be targeting a non-supported *Z80* architecture or building an operating system.

**libsdcc-z80** is the glue betweeen the *SDCC* C compiler and the
*Z80* processor. *Z80* lacks instructions for integer and 
floating point arithmetics.

To mitigate it, the *SDCC* C compiler replaces these non-existing
instructions with calls to special functions (such as: `__mulint`).
Invisible to you, the linker then links these special functions 
with your code.

This works in the *SDCC* realm, but if you prevent the compiler to link
default *SDCC* libraries then you need to provide these special functions,
and the `libsdcc-z80` does that.

## How to create bare metal program?

First you need a startup code. By convention you should call it `crt0.s` (*the C runtime*). This code must prepare the layout for your C program - configure the areas, initialize static variables, set the stack pointer, and jump to your `main()` function. You can find an example of `crt0.s` in the `sample` folder.

Then write your C program. And compile and link with **libsdcc-z80**. If your program is called `test.c`, here is teh compilation process that produces `test.bin`.

~~~z80
# Assemble crt0.s
sdasz80 -xlos -g crt0.s

# Compile test.c
sdcc -o test.rel \
     -c --std-c11 -mz80 --debug \
     --nostdinc --no-std-crt0 --nostdlib \
     test.c
    
# Link both
sdcc -o test.ihx \
     -mz80 -Wl -y \
     --code-loc 0x8000 --data-loc 0x8600 \
     --std-c11 -mz80 --debug\
     --no-std-crt0 --nostdinc --nostdlib \
     -L../bin -llibsdcc-z80 \
     crt0.rel test.rel

# Finally, convert ihx to binary
sdobjcopy -I ihex -O binary test.ihx test.bin
~~~

 > When linking you must pass `crt0.rel` as the first linker file! 

## Compiling the libsdcc-z80

Use `make` command in the root directory. This will build the library inside the  `build` directory and copy the binary `libsdcc-z80.lib` into the `bin` directory.

### Custom build and bin folders

To chain compile the library from your project, you can pass absolute directories as variables `BUILD_DIR` and `BIN_DIR`.

`make BUILD_DIR=~/myproj/build BIN_DIR=~/myproj/bin`

### Sample

This directory contains of a bare metal Z80 program that compiles to the `0x8000` address (data segment to `0x8100`) and tests basic `long`, `long long`, and `float` operations.

Consult `Makefile` for details.

### Precompiled library is available in the git repo

Latest precompiled library readily available in the `bin` directory.

[language.url]:   https://en.wikipedia.org/wiki/ANSI_C
[language.badge]: https://img.shields.io/badge/language-C-blue.svg

[standard.url]:   https://en.wikipedia.org/wiki/C11_(C_standard_revision)
[standard.badge]: https://img.shields.io/badge/standard-C11-blue.svg

[license.url]:    https://github.com/tstih/nice/blob/master/LICENSE
[license.badge]:  https://img.shields.io/badge/license-MIT-blue.svg

[status.badge]:  https://img.shields.io/badge/status-stable-darkgreen.svg