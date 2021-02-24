#!/bin/bash

boot_conf=""
boot_conf_root=""
config_paths=( ${SKIFF_CONFIG_PATH} )
for (( idx=${#config_paths[@]}-1 ; idx>=0 ; idx-- )) ; do
  conf_i_res="${config_paths[idx]}/resources/boot-scripts"
  if [ ! -d $conf_i_res ]; then
    continue
  fi
  boot_txt="$conf_i_res/boot.txt"
  boot_ini="$conf_i_res/boot.ini"

  boot_conf_root="${config_paths[idx]}"
  if [ -f $boot_txt ]; then
    echo "Using boot.txt at $boot_txt"
    boot_conf="$boot_txt"
    break
  fi

  if [ -f "$boot_ini" ]; then
    echo "Using boot.ini at ${boot_ini}"
    boot_conf="$boot_ini"
    break
  fi
done

if [ -z "$boot_conf" ]; then
  echo "Unable to find boot script!"
  exit 1
fi

export boot_conf
export boot_conf_root
