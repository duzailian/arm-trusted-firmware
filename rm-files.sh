#!/bin/bash

chmod 777 ./build.sh ./rm-files.py


make distclean

# bear -- ./build.sh
./rm-files.py compile_commands.json


# 如下更新以下命令，需要使用如下命令:
# file=$(./build.sh 2>&1  | grep include  |   awk 'match($0, /<([^>]+)>|"([^"]+)"/, a) {print a[1] ? a[1] : a[2]}' )&& git status |grep ${file}
#
git checkout bl2u/bl2u.ld.S
git checkout plat/arm/board/fvp/include/plat.ld.S
git checkout bl31/bl31.ld.S
git checkout include/lib/pmf/aarch64/pmf_asm_macros.S
git checkout bl2/bl2.ld.S
git checkout bl1/bl1.ld.S
git checkout lib/cpus/aarch64/wa_cve_2022_23960_bhb.S
git checkout lib/cpus/aarch64/wa_cve_2022_23960_bhb_vector.S
git checkout include/plat/arm/common/aarch64/arm_macros.S
git checkout include/arch/aarch64/asm_macros.S
git checkout include/common/asm_macros_common.S
git checkout include/arch/aarch64/assert_macros.S
git checkout include/arch/aarch64/el3_common_macros.S
git checkout include/arch/aarch64/console_macros.S
git checkout plat/arm/board/fvp/include/plat_macros.S
git checkout lib/cpus/aarch64/wa_cve_2022_23960_bhb_vector.S
git checkout lib/cpus/aarch64/wa_cve_2022_23960_bhb.S
git checkout bl1/bl1.ld.S
git checkout bl2/bl2.ld.S
git checkout include/lib/pmf/aarch64/pmf_asm_macros.S
git checkout bl31/bl31.ld.S
git checkout plat/arm/board/fvp/include/plat.ld.S
git checkout include/lib/cpus/aarch64/cpu_macros.S


# 删除plat目录下除arm和common之外的所有文件夹
find plat -mindepth 1 -maxdepth 1 -type d ! -name 'arm' ! -name 'common' -exec rm -rf {} +

rm -rf  drivers/st/ drivers/marvell/ drivers/brcm/ drivers/allwinner/ drivers/nxp/ drivers/ti/ drivers/amlogic/ drivers/renesas/

# 删除plat/arm/board/目录下除fvp和common之外的所有文件夹
find plat/arm/board/  -mindepth 1 -maxdepth 1 -type d ! -name 'fvp' ! -name 'common' -exec rm -rf {} +

find include/plat/  -mindepth 1 -maxdepth 1 -type d ! -name 'arm' ! -name 'common' -exec rm -rf {} +
fd "^aarch32$" -x rm  -rf
