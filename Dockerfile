# Using multi-stage build.

### First stage: build an entire Gentoo with Musl and Clang globally, without GCC and GNU-binutils. ###

# Pulling official stage3-amd64-musl Gentoo image
FROM gentoo/stage3:amd64-musl AS build1

# Setting ARGs for Portage
ARG MAKEOPTS="" \
    LLVM_VERSION="llvm-14" \
    ACCEPT_KEYWORDS="~amd64" \
    EMERGE_DEFAULT_OPTS="--verbose" \
    CMAKE_MAKEFILE_GENERATOR="ninja" \
    PROFILE="default/linux/amd64/17.0/musl/llvm-toolchain"

# Creating necessary directories
RUN mkdir -p /etc/portage/repos.conf /etc/portage/env /etc/portage/profile 

# Copying rsync and git gentoo repository config.
COPY ./files/repos.conf /etc/portage/repos.conf/gentoo.conf
COPY ./files/repos2.conf ./gentoo.conf

# Updating gentoo tree with rsync, install eselect-repository and git, switch to git repository and update sys-apps/portage.
RUN emerge-webrsync \
&& emerge app-eselect/eselect-repository dev-vcs/git \
&& eselect repository enable musl \
&& eselect repository add clang-musl git https://github.com/clang-musl-overlay/clang-musl-overlay.git \
&& rm -rf /var/db/repos/gentoo \
&& mv gentoo.conf /etc/portage/repos.conf/gentoo.conf \
&& emerge --sync \
&& emerge -1 sys-apps/portage \
&& rm -rf /var/tmp/portage/*

# This package.use.force remove all LLVM_TARGETS, except X86.
COPY ./files/package.use.force /etc/portage/profile/package.use.force

# Bootstraping Rust first it's necessary, because after removing GCC, no more possible to install.
# because LLVM and Clang utilizes llvm-libunwind, and this is imcompatible with rust-bin used to bootstrap Rust.
RUN USE="-binutils-plugin -sanitize default-compiler-rt default-lld \
    default-libcxx llvm-libunwind libunwind system-llvm" emerge dev-lang/rust::clang-musl

# Clone gentoo-patchset by Leonardo Neumann to fix some package errors, set musl-llvm-toolchain profile,
# remove GCC, GCC-config and GNU-binutils, and set clang/llvm binutils as default.
RUN git clone --depth=1 https://github.com/leonardohn/gentoo-patchset.git /etc/portage/patches \
&& rm -rf /etc/portage/profile \
&& eselect profile set --force "clang-musl:$PROFILE" \
&& eselect env update \
&& source /etc/profile \
&& emerge -C sys-devel/gcc sys-devel/gcc-config sys-devel/binutils \
&& emerge sys-devel/llvm-conf \
&& rm -rf /etc/portage/env /etc/portage/package.env \
&& llvm-conf $LLVM_VERSION --enable-native-links --enable-clang-wrappers --enable-binutils-wrappers \
&& emerge --depclean

# At this moment, patch used by iptables is no more necessary.
# Rebuild everything with Clang/LLVM toolchain.
# NOTE: If dev-vcs/git fail to build, add "--exclude 'dev-vcs/git'" option after [...] -e @world.
RUN rm -rf /etc/portage/patches/net-firewall \
&& emerge -e @world

# Create a full backup tar to utilize on next stage build.
COPY ./files/mkstage.sh /mkstage.sh
RUN chmod +x /mkstage.sh && bash /mkstage.sh

### Second stage:  copy previous full backup tar and make stage3 using Catalyst tool.

# Using stage3-no-multilib-gentoo image
FROM gentoo/stage3:nomultilib AS build2

# Create portage repository directory and Catalyst directory build.
RUN mkdir -p /etc/portage/repos.conf /var/tmp/catalyst/builds/clang-musl

# Copy rsync and git repository config.
COPY ./files/repos.conf /etc/portage/repos.conf/gentoo.conf
COPY ./files/repos2.conf /gentoo.conf

# Update tree, switch rsync to git repository, install Catalyst build tool and clone necessary repositories
# to build a stage3 gentoo.
RUN emerge-webrsync \
&& emerge dev-vcs/git app-eselect/eselect-repository \
&& mv /gentoo.conf /etc/portage/repos.conf/gentoo.conf \
&& rm -rf /var/db/repos/gentoo \
&& emerge --sync \
&& USE="-iso" emerge dev-util/catalyst app-arch/pixz \
&& rm -rf /var/cache/binpkgs/* \
&& rm -rf /var/cache/distfiles/* \
&& rm -rf /var/tmp/portage/* \
&& eselect repository add clang-musl git https://github.com/clang-musl-overlay/clang-musl-overlay \
&& emaint sync -r clang-musl \
&& cd /var/db/repos/clang-musl \
&& git clone https://github.com/gentoo/releng.git \
&& eselect repository enable musl \
&& emaint sync -r musl

# Copy stage specs and catalyst bash script.
# At this moment, trying creating stage1 first.
COPY ./specs/stage1.spec /stage1.spec
COPY ./files/catalyst.sh /catalyst.sh

# Copy previous full backup tar created by first stage, to be used on Catalyst tool.
COPY --from=build1 /mnt/stage/stage3-amd64-musl-latest.tar.xz /var/tmp/catalyst/builds/clang-musl/stage3-amd64-musl-latest.tar.xz

# Make script executable
RUN chmod +x /catalyst.sh

# Run catalyst.
CMD [ "/catalyst.sh" ]
