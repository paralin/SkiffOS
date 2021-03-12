# Anbox

This package will run [Anbox] in a container.

It enables kernel options required, as well as other firmware/support packages.

[Anbox]: https://github.com/anbox/anbox

## Anbox in Skiff Core

TODO

If Skiff Core is enabled with `skiff/core`, this package enables the Anbox core
image. If you wish to override the anbox core, specify a different core image
following the anbox package - i.e. `skiff/core,android/anbox,core/gentoo`.

Alternatively enable just the Android support with `android/common`.
