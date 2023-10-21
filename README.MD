Makefile and Nix files for building the [blinky example from Rust's stm32f4xx-hal](https://github.com/stm32-rs/stm32f4xx-hal/blob/master/examples/blinky-timer-irq.rs),
and using [`uf2conv`](https://github.com/microsoft/uf2/commits/master/utils/uf2conv.py) so that it can be flashed to a device which use the [adafruit's tinyuf2 bootloader](https://github.com/adafruit/tinyuf2/).

To use `flake.nix`:

```
nix build .#firmware-uf2
```

To use the Makefile:

```
make rgoulter-stm32f401-blinky.uf2
```

To use justfile:

```
just make-and-flash rgoulter-stm32f401-blinky
```
