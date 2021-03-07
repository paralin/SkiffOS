#!/bin/bash

if [ -n "$SKIFF_RUN_INIT_ACTIONS" ]; then
  echo "Triggering intel microcode late loading..."
  echo 1 > /sys/devices/system/cpu/microcode/reload || true
fi
