FROM gentoo/stage3:amd64-musl

COPY ./files/package.use.force ./files/repos.conf ./files/repos2.conf ./

ARG MAKEOPTS="" \
    LLVM_VERSION="llvm-14" \
    ACCEPT_KEYWORDS="~amd64" \
    CMAKE_MAKEFILE_GENERATOR="ninja" \
    EMERGE_DEFAULT_OPTS="--verbose --quiet-build=y" \
    PROFILE="default/linux/amd64/17.0/musl/llvm-toolchain"

RUN mkdir -p /etc/portage/repos.conf /etc/portage/env /etc/portage/profile \
 && mv ./repos.conf /etc/portage/repos.conf/gentoo.conf \
 && emerge-webrsync \
 && emerge app-eselect/eselect-repository dev-vcs/git \
 && eselect repository enable musl \
 && eselect repository add clang-musl git \
    https://github.com/clang-musl-overlay/clang-musl-overlay.git \
 && rm -rf /var/db/repos/gentoo \
 && mv ./repos2.conf /etc/portage/repos.conf/gentoo.conf \
 && emerge --sync \
 && emerge -1 sys-apps/portage \
 && rm -rf /var/tmp/portage/* \
 && mv ./package.use.force /etc/portage/profile

RUN USE="-binutils-plugin" emerge --oneshot llvm::clang-musl

RUN USE="-sanitize default-compiler-rt default-lld \
    default-libcxx libcxx llvm-libunwind libunwind" emerge --oneshot clang

RUN USE="default-libcxx llvm-libunwind \
    system-bootstrap system-llvm" emerge rust::clang-musl

RUN git clone --depth=1 \
    https://github.com/leonardohn/gentoo-patchset.git /etc/portage/patches \
 && rm -rf /etc/portage/profile \
 && eselect profile set --force "clang-musl:$PROFILE" \
 && eselect env update \
 && source /etc/profile \
 && emerge -C sys-devel/gcc sys-devel/gcc-config sys-devel/binutils \
 && emerge sys-devel/llvm-conf \
 && rm -rf /etc/portage/env /etc/portage/package.env \
 && llvm-conf $LLVM_VERSION --enable-native-links \
    --enable-clang-wrappers --enable-binutils-wrappers \
 && emerge --depclean

RUN emerge --exclude=dev-vcs/git -e @world

RUN emerge @preserved-rebuild

RUN rm -rf \
    /var/db/repos/* \
    /var/cache/binpkgs/* \
    /var/cache/distfiles/* \
    /var/log/* \
    /var/tmp/portage/* \
 && echo -e "\nACCEPT_KEYWORDS=\"${ACCEPT_KEYWORDS}\"\n" \
    >> /etc/portage/make.conf

