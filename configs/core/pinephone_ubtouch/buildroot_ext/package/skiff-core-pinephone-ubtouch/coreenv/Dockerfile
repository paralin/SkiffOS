FROM skiffos/pinephone-ubtouch-base:latest

# systemd
ENV \
    container=docker \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# disable wifi and ethernet management
ADD ./network-manager.conf /etc/NetworkManager/conf.d/02-skiff-core.conf
# disable networking management
ADD ./networking /etc/default/networking
# disable udisks mount for mmcblk
ADD ./udev.rules /etc/udev/rules.d/02-skiff-core.conf

# mask some units
RUN \
  systemctl mask -f \
    console-getty getty@tty1.service serial-getty@ttyS0.service \
    sshd repowerd cgproxy session-watchdog \
    NetworkManager NetworkManager-wait-online

WORKDIR /
ENTRYPOINT ["/sbin/init"]
