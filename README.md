# Using Docker to build Gentoo Linux stage3
### WIP Project

This is a experiment project envolving Docker to build and automate custom stage3 of Gentoo Linux. The main differences between my custom stages and official stages are:

- `Clang/LLVM` as primary compiler;
- `Musl` as default Libc.
- `Hardend` profile provided.

## Building

Install Docker in your machine, and run `docker build -t <insertyourtag> .` Take a little time to build, so sit back, take a coffee and relax. 

Errors are expected. Consider opening a bug report to help this project.

## Special thanks

Special thanks to Leonardo Neumann, The CyberDuck and your `clang-musl` overlay:
- `https://github.com/clang-musl-overlay/clang-musl-overlay`

