#!/bin/bash
export CROSS_COMPILE=/opt/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
__CC=`which clang`
# 编译支持PIE的bl31
#make CC=${__CC} PLAT=fvp RESET_TO_BL31=1 ENABLE_PIE=1 bl31
make CC=${__CC} PLAT=fvp all
