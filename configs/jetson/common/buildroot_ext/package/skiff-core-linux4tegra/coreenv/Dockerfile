# Download the linux4tegra sources including nvidia packages.
# Subject to the NVIDIA Customer License.
FROM ubuntu:latest AS nvsources

# install wget + make data dir
RUN mkdir -p /data /sources && \
  export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confold"  \
  build-essential \
  rsync \
  lsb-release \
  wget curl git unzip \
  autotools-dev locales \
  && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# download sources
ENV L4T_URL https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/t186/tegra186_linux_r32.5.1_aarch64.tbz2
ENV L4T_TAR linux4tegra-aarch64.tbz2
RUN wget -q "${L4T_URL}" -O /data/${L4T_TAR}

# extract sources
# move kernel debs into nv debs dir
RUN mkdir -p /sources/linux4tegra && \
  tar --strip-components=1 -xf /data/${L4T_TAR} \
  -C /sources/linux4tegra && \
  mv /sources/linux4tegra/kernel/*.deb \
  /sources/linux4tegra/nv_tegra/l4t_deb_packages/ && \
  mv /sources/linux4tegra/tools/*.deb \
  /sources/linux4tegra/nv_tegra/l4t_deb_packages/

# configure debian packages to point to mock paths
COPY ./patch-debs.bash /sources/patch-debs.bash
RUN mkdir -p /sources/l4t_debs_workdir /sources/l4t_debs_patched && \
  cd /sources/l4t_debs_workdir && \
  bash /sources/patch-debs.bash && \
  cd ../ && rm -rf /sources/l4t_debs_workdir

# Ubuntu upstream
FROM ubuntu:18.04

# NVIDIA upstream
# FROM nvcr.io/nvidia/l4t-base:r32.4.3

# setup environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    container=docker \
    L4T_VERSION=32.5.1 \
    L4T_SOC=t186

# All packages, including requisite packages for nvidia.
# Also installs l4t_deb_packages.
RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
  build-essential \
  openssh-client \
  rsync \
  lsb-release \
  systemd \
  device-tree-compiler \
  usbutils \
  sudo \
  curl \
  htop \
  git \
  sed \
  libunwind8 \
  vim \
  nano \
  net-tools \
  software-properties-common \
  unzip \
  autotools-dev \
  cups \
  locales \
  wget # &&

# copy l4t_deb_packages
COPY --from=nvsources /sources/l4t_debs_patched \
  /usr/src/l4t_deb_packages

# copy nv_boot_control
COPY --from=nvsources /sources/linux4tegra/bootloader/nv_boot_control.conf \
  /etc/nv_boot_control.conf

# setup nv-boot-control.conf
# Set board spec: BOARD_ID-FAB-BOARDSKU-BOARDREV-NV_PRODUCTION-CHIP_REV-BOARD_NAME-ROOTFS_DEV
#
#  BOARDID  BOARDSKU  FAB  BOARDREV
#  --------------------------------+--------+---------+----+---------
#  jetson-tx1                       2180     0000      400  N/A
#  jetson-tx2                       3310     1000      B02  N/A
#  jetson-xavier                    2888     0001      400  H.0
#  jetson-nano-emmc                 3448     0002      200  N/A
#  jetson-xavier-nx-devkit-emmc     3668     0001      100  N/A
#  --------------------------------+--------+---------+----+---------
RUN rootfs_dir=/; \
  BOARDID=2180; BOARDSKU=1000; CHIPID="0x18"; FAB=B02; FUSELEVEL=fuselevel_production; \
  hwchiprev="0"; ext_target_board="jetson_tx2_devkit"; target_rootdev="mmcblk0p1"; \
  ota_boot_dev="/dev/mmcblk0boot0"; ota_gpt_dev="/dev/mmcblk0boot1"; \
  spec="${BOARDID}-${FAB}-${BOARDSKU}-${BOARDREV}-1-${hwchiprev}-${ext_target_board}-${target_rootdev}"; \
  sed -i '/TNSPEC/d' "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i "$ a TNSPEC ${spec}" "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i '/TEGRA_CHIPID/d' "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i "$ a TEGRA_CHIPID ${CHIPID}" "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i '/TEGRA_OTA_BOOT_DEVICE/d' "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i "$ a TEGRA_OTA_BOOT_DEVICE ${ota_boot_dev}" "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i '/TEGRA_OTA_GPT_DEVICE/d' "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i "$ a TEGRA_OTA_GPT_DEVICE ${ota_gpt_dev}" "${rootfs_dir}/etc/nv_boot_control.conf"

# setup device-tree path for reference for debs
RUN mkdir -p /etc/tegra-soc/device-tree && \
  echo "nvidia,quillnvidia,p2597-0000+p3310-1000nvidia,tegra186" >\
    /etc/tegra-soc/device-tree/compatible

RUN apt-get install -y \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
  /usr/src/l4t_deb_packages/*.deb && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /usr/src/l4t_deb_packages

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# lightdm and graphics
RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
  lightdm xorg locales lightdm-gtk-greeter \
  desktop-base mesa-utils x11-apps xinput xinit \
  xserver-xorg-input-all \
  && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# Extra: full desktop environment
# not working: kde-plasma-desktop vlc
RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confold"  \
  libgles2-mesa-dev libsdl2-dev libblas3 \
  liblapack3  lightdm \
  mesa-utils ncurses-term \
  lxde vlc mplayer \
  ark gwenview kate kcalc kde-spectacle \
  khelpcenter knotes okular plasma-dataengines-addons \
  plasma-pa plasma-runners-addons plasma-widgets-addons \
  polkit-kde-agent-1 sweeper \
  chromium-browser \
  x11vnc xorg \
  xserver-xorg-input-all \
  && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

RUN \
  adduser nvidia \
  --no-create-home \
  --gecos "NVIDIA User" \
  --shell /bin/bash \
  --disabled-password && \
  adduser nvidia sudo && \
  adduser nvidia root && \
  adduser nvidia systemd-journal && \
  adduser nvidia dialout && \
  adduser nvidia video && \
  adduser nvidia plugdev && \
  echo "nvidia:nvidia" | chpasswd && \
  mkdir -p /home/nvidia/.cache/ && \
  chown -R nvidia:nvidia /home/nvidia

RUN systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    rm /etc/systemd/system/nvwifibt.service && \
    echo "nvidia	ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*NetworkManager*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

WORKDIR /home/nvidia
ENTRYPOINT ["/lib/systemd/systemd"]
