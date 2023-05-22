#!/bin/bash
export CROSS_COMPILE=/opt/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
__CC=`which clang`
make CC=${__CC} PLAT=fvp all
