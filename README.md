# The SDCC Z80 bare metal library

This library is the glue betweeen the *SDCC* C compiler and the
*Z80* processor. *Z80* lacks instructions for integer and 
floating point arithmetics.

To mitigate it, the *SDCC* C compiler replaces these non-existing
instructions with calls to special functions (such as: `__mulint`).
Invisible to you, the linker then links these special functions 
with your code.

This works in the *SDCC* realm, but if you prevent the compiler to link
default *SDCC* libraries (by using directives `--nostdlib`, `--nostdinc`, 
and `--no-std-crt0`) then you need to provide these special functions,
and the `libsdcc-z80` does that.

# How to use it?

## Compilation

Compile it with `make`. This will build the library inside the  `build`
directory and copy the library file `libsdcc-z80.lib` into the `bin` 
directory.

## Custom build and bin folders

To chain make file from your make file, pass absolute directories as variables `BUILD_DIR` and `BIN_DIR`, like this -

`make BUILD_DIR=~/myproj/build`

## Link with your project

You must prevent SDCC to link its own version of glue by using compilation switches `--nostdlib`, `--nostdinc`,  and `--no-std-crt0`. Provide your own `crt0.s` startup file and link with `-l libsdcc-z80`.

See the `sample` folder for an example of bare metal program.

# Precompiler library

Precompiled library is in the `bin` folder.