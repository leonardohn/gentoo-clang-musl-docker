subarch: amd64
target: stage1
version_stamp: clang-musl-@TIMESTAMP@
rel_type: clang-musl
profile: clang-musl:default/linux/amd64/17.0/musl/llvm-toolchain
snapshot: latest
source_subpath: clang-musl/stage3-amd64-musl-latest
chost: x86_64-gentoo-linux-musl
portage_prefix: releng
portage_overlay: /var/db/repos/musl /var/db/repos/clang-musl
portage_confdir: /var/db/repos/clang-musl/releng/releases/portage/stages
update_seed: yes
update_seed_command: --update --deep --newuse @world
compression_mode: pixz
