/*
 * Copyright (c) 2013-2019, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <assert.h>
#include <errno.h>
#include <string.h>

#include <common/debug.h>
#include <common/runtime_svc.h>

/*******************************************************************************
 * The 'rt_svc_descs' array holds the runtime service descriptors exported by
 * services by placing them in the 'rt_svc_descs' linker section.
 * The 'rt_svc_descs_indices' array holds the index of a descriptor in the
 * 'rt_svc_descs' array. When an SMC arrives, the OEN[29:24] bits and the call
 * type[31] bit in the function id are combined to get an index into the
 * 'rt_svc_descs_indices' array. This gives the index of the descriptor in the
 * 'rt_svc_descs' array which contains the SMC handler.
 ******************************************************************************/
uint8_t rt_svc_descs_indices[MAX_RT_SVCS];/*运行服务索引数组、OEN+调用类型最多128种*/

#define RT_SVC_DECS_NUM		((RT_SVC_DESCS_END - RT_SVC_DESCS_START)\
					/ sizeof(rt_svc_desc_t))/*单位:字节数，计算注册的运行时服务数*/

/*******************************************************************************
 * Function to invoke the registered `handle` corresponding to the smc_fid in
 * AArch32 mode.
 ******************************************************************************/
uintptr_t handle_runtime_svc(uint32_t smc_fid,
			     void *cookie,
			     void *handle,
			     unsigned int flags)
{
	u_register_t x1, x2, x3, x4;
	unsigned int index;
	unsigned int idx;
	const rt_svc_desc_t *rt_svc_descs;

	assert(handle != NULL);
	idx = get_unique_oen_from_smc_fid(smc_fid);
	assert(idx < MAX_RT_SVCS);

	index = rt_svc_descs_indices[idx];
	if (index >= RT_SVC_DECS_NUM)
		SMC_RET1(handle, SMC_UNK);

	rt_svc_descs = (rt_svc_desc_t *) RT_SVC_DESCS_START;

	get_smc_params_from_ctx(handle, x1, x2, x3, x4);

	return rt_svc_descs[index].handle(smc_fid, x1, x2, x3, x4, cookie,
						handle, flags);
}

/*******************************************************************************
 * Simple routine to sanity check a runtime service descriptor before using it
 ******************************************************************************/
static int32_t validate_rt_svc_desc(const rt_svc_desc_t *desc)
{
	if (desc == NULL) {
		return -EINVAL;
	}
	if (desc->start_oen > desc->end_oen) {
		return -EINVAL;
	}
	if (desc->end_oen >= OEN_LIMIT) {
		return -EINVAL;
	}
	if ((desc->call_type != SMC_TYPE_FAST) &&
	    (desc->call_type != SMC_TYPE_YIELD)) {
		return -EINVAL;
	}
	/* A runtime service having no init or handle function doesn't make sense */
	if ((desc->init == NULL) && (desc->handle == NULL)) {
		return -EINVAL;
	}
	return 0;
}

/*******************************************************************************
 * This function calls the initialisation routine in the descriptor exported by
 * a runtime service. Once a descriptor has been validated, its start & end
 * owning entity numbers and the call type are combined to form a unique oen.
 * The unique oen is used as an index into the 'rt_svc_descs_indices' array.
 * The index of the runtime service descriptor is stored at this index.
 ******************************************************************************/
void __init runtime_svc_init(void)
{
	int rc = 0;
	uint8_t index, start_idx, end_idx;
	rt_svc_desc_t *rt_svc_descs;

	/* Assert the number of descriptors detected are less than maximum indices */
	assert((RT_SVC_DESCS_END >= RT_SVC_DESCS_START) &&
			(RT_SVC_DECS_NUM < MAX_RT_SVCS));/*判断链接脚本导出描述符区间是否合法，服务数最大为128*/

	/* If no runtime services are implemented then simply bail out */
	if (RT_SVC_DECS_NUM == 0U) {
		return;/*没有实现运行服务则直接return*/
	}
	/* Initialise internal variables to invalid state */
	/*将服务索引数组成员全部初始化为FF,避免随机值导致误用，void显式忽略返回值*/
	(void)memset(rt_svc_descs_indices, -1, sizeof(rt_svc_descs_indices));

	rt_svc_descs = (rt_svc_desc_t *) RT_SVC_DESCS_START;/*强转一下，将描述符数组首地址指向第一个服务的地址*/
	for (index = 0U; index < RT_SVC_DECS_NUM; index++) {/*逐个遍历所有运行时服务*/
		rt_svc_desc_t *service = &rt_svc_descs[index];

		/*
		 * An invalid descriptor is an error condition since it is
		 * difficult to predict the system behaviour in the absence
		 * of this service.
		 */
		rc = validate_rt_svc_desc(service);/*检查当前描述符是否合法，此处考虑静态编译阶段的问题*/
		if (rc != 0) {
			ERROR("Invalid runtime service descriptor %p\n",
				(void *) service);
			panic();/*非法描述符一个都不允许存在，后续调进来会死机，直接崩溃*/
		}

		/*
		 * The runtime service may have separate rt_svc_desc_t
		 * for its fast smc and yielding smc. Since the service itself
		 * need to be initialized only once, only one of them will have
		 * an initialisation routine defined. Call the initialisation
		 * routine for this runtime service, if it is defined.
		 */
		if (service->init != NULL) {/*若服务的初始化函数非空，则执行初始化*/
			rc = service->init();
			if (rc != 0) {
				ERROR("Error initializing runtime service %s\n",
						service->name);
				continue;/*初始化失败不影响下一次迭代，continue关键字跳过当前循环的剩余部分*/
			}
		}

		/*
		 * Fill the indices corresponding to the start and end
		 * owning entity numbers with the index of the
		 * descriptor which will handle the SMCs for this owning
		 * entity range.
		 */
		start_idx = (uint8_t)get_unique_oen(service->start_oen,
						    service->call_type);/*强转为8位满足最大128的需求*/
		end_idx = (uint8_t)get_unique_oen(service->end_oen,
						  service->call_type);
		assert(start_idx <= end_idx);
		assert(end_idx < MAX_RT_SVCS);
		for (; start_idx <= end_idx; start_idx++) {
			rt_svc_descs_indices[start_idx] = index;
		}
	}
}
