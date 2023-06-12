/*
 * Copyright (c) 2020, Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <arch.h>
#include <asm_macros.S>

	.global	mtpmu_disable

/* -------------------------------------------------------------
 * The functions in this file are called at entrypoint, before
 * the CPU has decided whether this is a cold or a warm boot.
 * Therefore there are no stack yet to rely on for a C function
 * call.
 * -------------------------------------------------------------
 */

/*
 * bool mtpmu_supported(void)
 *
 * Return a boolean indicating whether FEAT_MTPMU is supported or not.
 *
 * Trash registers: x0, x1
	检查是否支持MTPMU(Multi-threaded PMU Extensions )
 */
func mtpmu_supported
	mrs	x0, id_aa64dfr0_el1
	mov_imm	x1, ID_AA64DFR0_MTPMU_MASK
	and	x0, x1, x0, LSR #ID_AA64DFR0_MTPMU_SHIFT
	cmp	x0, ID_AA64DFR0_MTPMU_SUPPORTED
	cset	x0, eq
	ret
endfunc mtpmu_supported

/*
 * bool el_implemented(unsigned int el_shift)
 *
 * Return a boolean indicating if the specified EL is implemented.
 * The EL is represented as the bitmask shift on id_aa64pfr0_el1 register.
 *
 * Trash registers: x0, x1
 */
func el_implemented
	mrs	x1, id_aa64pfr0_el1
	lsr	x1, x1, x0
	cmp	x1, #ID_AA64PFR0_ELX_MASK
	cset	x0, eq
	ret
endfunc el_implemented

/*
 * void mtpmu_disable(void)
 *
 * Disable mtpmu feature if supported.
 *
 * Trash register: x0, x1, x30
 */
func mtpmu_disable
	mov	x10, x30
	bl	mtpmu_supported /* 检查是否支持MTPMU(Multi-threaded PMU Extensions) */
	cbz	x0, exit_disable /* 不支持MTPMU,直接返回 */

	/* FEAT_MTMPU Supported */
	mov_imm	x0, ID_AA64PFR0_EL3_SHIFT
	bl	el_implemented /* 检查是否已实现EL3 */
	cbz	x0, 1f /* 未实现EL3,跳转到1f */

	/* EL3 implemented */
	mrs	x0, mdcr_el3
	mov_imm x1, MDCR_MTPME_BIT
	bic	x0, x0, x1
	msr	mdcr_el3, x0 /* 关闭MTMPU功能(清除mdcr_el3中的MTPME位) */

	/*
	 * If EL3 is implemented, MDCR_EL2.MTPME is implemented as Res0 and
	 * FEAT_MTPMU is controlled only from EL3, so no need to perform
	 * any operations for EL2.
	 */
	isb
exit_disable:
	ret	x10
1:
	/* EL3 not implemented */
	mov_imm	x0, ID_AA64PFR0_EL2_SHIFT /* 检查是否已实现EL2 */
	bl	el_implemented
	cbz	x0, exit_disable /* 未实现EL2,直接返回 */

	/* EL2 implemented */
	mrs	x0, mdcr_el2
	mov_imm x1, MDCR_EL2_MTPME
	bic	x0, x0, x1
	msr	mdcr_el2, x0/* 关闭MTMPU功能(清除mdcr_el2中的MTPME位) */
	isb
	ret	x10
endfunc mtpmu_disable
