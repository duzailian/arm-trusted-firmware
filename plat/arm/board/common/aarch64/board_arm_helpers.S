/*
 * Copyright (c) 2015, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <asm_macros.S>
#include <common/bl_common.h>
#include <platform_def.h>

	.globl  plat_report_exception


	/* ---------------------------------------------
	 * void plat_report_exception(unsigned int type)
	 * Function to report an unhandled exception
	 * with platform-specific means.
	 * On FVP platform, it updates the LEDs
	 * to indicate where we are
	 * ---------------------------------------------
	 */
func plat_report_exception/* 报告异常 */
	mrs	x1, CurrentEl /* 获取当前异常等级 */
	lsr	x1, x1, #MODE_EL_SHIFT /* 逻辑右移2bits得到当前的异常等级 */
	lsl	x1, x1, #V2M_SYS_LED_EL_SHIFT /* 异常等级逻辑左移1bit */
	lsl	x0, x0, #V2M_SYS_LED_EC_SHIFT /* status code逻辑左移3bits */
	mov	x2, #(SECURE << V2M_SYS_LED_SS_SHIFT)/* 可信为0  */
	orr	x0, x0, x2
	orr	x0, x0, x1
	mov	x1, #V2M_SYSREGS_BASE
	add	x1, x1, #V2M_SYS_LED
	str	w0, [x1] /*写入寄存器*/
	ret
endfunc plat_report_exception
