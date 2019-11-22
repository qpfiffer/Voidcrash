This is a fantastic resource: [clicky.](https://pramode.in/2019/10/07/rust-on-riscv-board-sipeed-longan-nano/)
Also very useful: [here.](https://www.susa.net/wordpress/2019/10/longan-nano-gd32vf103/)

Pre-Install
===========

You'll need to get both [platformio]() and the Sipeed Longan Nano version of
`dfu-util`, although I think the one in Elementary worked out of the box. It
uploads but throws an error, which I think is a red herring.

HOW-TO
======

1. Set your device into upload mode by holding down the `BOOT` key and then
   pressing `RESET`.

1. Build the project:
```
platformio run
```

1. Upload via USB-C cable:
```
platformio run --target upload
```
