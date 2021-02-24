# Linux on LiteX VexRiscv

This configuration package builds a SkiffOS system for RiscV based on the
linux-on-litex-vexriscv sample project from LiteX.

The following example builds for riscv:

```sh
export SKIFF_CONFIG=litex/vexriscv
export SKIFF_WORKSPACE=litex
make configure compile
```

Reference:

 - https://github.com/enjoy-digital/litex
 - https://github.com/litex-hub/linux-on-litex-vexriscv
 - https://github.com/litex-hub/litex-boards

## Simulator

The SoC simulator from LiteX can be used to test the system:

```
# run the simulator
make cmd/litex/vexriscv/simulate
```

