#!/bin/bash
set -x

mkdir -p /var/tmp/catalyst/builds/clang-musl
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-musl/stage3-amd64-musl-20220501T170547Z.tar.xz \
    -O /var/tmp/catalyst/builds/clang-musl/stage3-amd64-musl-latest.tar.xz
catalyst -s latest
catalyst -f /stage1.spec
