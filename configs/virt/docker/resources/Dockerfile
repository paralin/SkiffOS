FROM scratch

ADD rootfs.tar /

ENV container=docker \
    init=/lib/systemd/systemd \
    LC_ALL=C

RUN find /etc/systemd/system \
         /usr/lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*udev*' \
         -or -name '*rdisc*' \
         -or -name '*freedesktop*' \
         -or -name '*persist-resize*' \
         -or -name '*NetworkManager*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

RUN systemctl set-default multi-user.target && \
    systemctl mask tmp.mount && \
    touch /etc/skip-skiff-mounts && \
    touch /etc/skip-skiff-journal-mounts

RUN echo '. /etc/profile' >> /root/.bashrc

VOLUME [ "/mnt/persist", "/mnt/rootfs" ]
ENTRYPOINT ["/usr/lib/systemd/systemd"]
