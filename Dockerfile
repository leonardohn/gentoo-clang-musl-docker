FROM gentoo/stage3:amd64-musl

RUN mkdir -p /etc/portage/repos.conf

COPY ./files/repos.conf /etc/portage/repos.conf/gentoo.conf

RUN emerge-webrsync
RUN emerge --quiet-build=y --quiet app-eselect/eselect-repository dev-vcs/git
RUN eselect repository enable musl

COPY ./files/repos2.conf /etc/portage/repos.conf/gentoo.conf

RUN rm -rf /var/db/repos/gentoo
RUN emerge --sync --quiet \
&& USE="-iso" emerge --quiet-build=y --quiet dev-util/catalyst \
&& emerge --quiet-build=y --quiet app-arch/pixz \
&& emerge --depclean --quiet \
&& rm -rf /var/cache/binpkgs/* \
&& rm -rf /var/cache/distfiles/* \
&& rm -rf /var/tmp/portage/*
RUN eselect repository add clang-musl git https://github.com/clang-musl-overlay/clang-musl-overlay \
&& emaint sync -r clang-musl
RUN cd /var/db/repos/clang-musl \
&& git clone https://github.com/gentoo/releng.git

COPY ./specs/stage1.spec /stage1.spec
COPY ./specs/stage2.spec /stage2.spec
COPY ./specs/stage3.spec /stage3.spec
COPY ./files/catalyst.sh /catalyst.sh

RUN chmod +x /catalyst.sh

CMD [ "/catalyst.sh" ]
