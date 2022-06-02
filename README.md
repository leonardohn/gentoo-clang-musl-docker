# Using Docker to build Gentoo Linux stage3
## WIP PROJECT! 

This is a experiment project envolving Docker to build and automate custom stage3 of Gentoo Linux. The main differences between my custom stages and official stages are:

- `Clang/LLVM` as primary compiler;
- `Musl` as default Libc.
- `Hardened` profile provided.

### Building

Install Docker in your machine, and run `docker build -t <insertyourtag> .` Take a little time to build, so sit back, take a coffee and relax. After ending, run `docker export -o stage.tar <insertyouprevioustag>`, and your fresh stage3-clang-musl-gentoo are done.

You can follow Gentoo Handbook documentation to continue your new installation:
`https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage`

Errors are expected. Consider opening a bug report to help this project.

### Common issues

`dev-vcs/git` build fails, and error log doesn't make any sense. An option `--exclude 'dev-vcs/git'` was added at the end of rebuild system step.

### Notes

Rust fails to install, because rust-bin is necessary to bootstrap rust, and rust-bin doesn't work if LLVM are installed with `llvm-libunwind` use flag. So this project boostrap and install Clang, LLVM and Rust with necessary modifications. Supposing you're looking for an exotic setup, this doesn't should a problem. 

In my case, I use Rust to build Firefox, Alacritty and Exa apps.

- `https://bugs.gentoo.org/733242`
- `https://github.com/rust-lang/rust/issues/84040`
- `https://github.com/rust-lang/rust/issues/76020`

### Special thanks

Special thanks to Leonardo Neumann, The CyberDuck and your `clang-musl` overlay:
- `https://github.com/clang-musl-overlay/clang-musl-overlay`

### References

- `https://wiki.gentoo.org/wiki/Clang`
- `https://wiki.gentoo.org/wiki/Project:Musl`
