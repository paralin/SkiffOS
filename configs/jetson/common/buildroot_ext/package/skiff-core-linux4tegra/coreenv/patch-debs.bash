#!/bin/bash
set -eo pipefail

for dpkgf in /sources/linux4tegra/nv_tegra/l4t_deb_packages/*.deb; do
    if [ -d ./workdir ]; then
      rm -rf ./workdir || true
    fi
    mkdir -p ./workdir
    dpkg-deb -R $dpkgf ./workdir
    if FILES=$(grep -l -r 'device-tree/compatible' ./workdir/DEBIAN); then
        echo "Patching file $(basename $dpkgf)..."
        sed -i \
            -e 's#/proc/device-tree/compatible#/etc/tegra-soc/device-tree/compatible#g' \
            ${FILES}
        dpkg-deb -b workdir /sources/l4t_debs_patched/$(basename $dpkgf)
    else
        cp $dpkgf /sources/l4t_debs_patched/$(basename $dpkgf)
    fi
done
