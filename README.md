# Snake
A snake game for the ZX Spectrum written in Z80 assembler

# Building

## Required tools

You need sjasmplus installed on your path. It can be cloned from
https://github.com/z00m128/sjasmplus.git. Currently, you can only
build from within VsCode, tasks.json is used as build system which
is not great, but sort of works. In order to run, you need the
DeZog VsCode extension.

To generate a `.tzx` file, run the build task `GenerateTapeFile` in VsCode.

# fuse-emulator-utils



Needed for creating the .tzx file. Can be installed using apt `install fuse-emulator-utils`.

## Recommended tools

- Z80 Instruction Set (VsCode extension) - mouse-over instruction reference of assembler instructions.
- ASM Code Lens (VsCode extension) - only syntax highlighting extension I've found that works.
- ZX Graphics Editor (VsCode extension)
