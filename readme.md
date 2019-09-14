# Keyword spotting on STM32F746G-DISCO development board

This repository is a copy of github.com/ARM-software/ML-KWS-for-MCU project with a little changes for successfully build with GNU Arm Embedded Toolchain

## Get binary

To compile the project you need to download GNU Arm Embedded Toolchain from the website 'https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads'

```bash
  export COMPILERDIR=~/path/to/gcc-arm-none-eabi-8-2019-q3-update/bin
  git clone https://github.com/alxkbr/ml-kws-for-mcu.git
  cd ml-kws-for-mcu
  make
```

After compiling source code, the firmware will located in the 'build' folder.
