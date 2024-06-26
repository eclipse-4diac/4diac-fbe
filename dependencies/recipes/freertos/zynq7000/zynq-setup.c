/********************************************************************************
# Copyright (c) 2020, 2024 OFFIS e.V.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
# 
# Contributors:
#    Jörg Walter - initial implementation
# *******************************************************************************/
/*
 * This file contains code from FreeRTOS V202012.00
 * Copyright (C) 2020 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * http://www.FreeRTOS.org
 * http://aws.amazon.com/freertos
 */

#include <stdint.h>
#include <FreeRTOS.h>
#include "xscugic.h"
#include "xuartps_hw.h"
#include "xscutimer.h"
#include <limits.h>
#include <debug-printf.h>

#ifdef NDEBUG
/* disable debugging output */
#define debug(...)
#else
#define debug debug_printf
#endif

/* ********************************************************************* */
/* Provide a minimum viable hardware initialisation routine, can be overridden
 * by the application. (based on the Zynq demo's main.c) */


XScuWdt xWatchDogInstance;
extern XScuGic xInterruptController;

extern void vPortInstallFreeRTOSVectorTable(void);

__attribute__((weak, constructor(101)))
void vSetupHardware()
{
    debug("prvSetupHardware(): default implementation called\n");
	/* Ensure no interrupts execute while the scheduler is in an inconsistent
     * state. Interrupts are automatically enabled when the scheduler is
     * started. */
	portDISABLE_INTERRUPTS();

	/* Obtain the configuration of the GIC. */
	XScuGic_Config *pxGICConfig = XScuGic_LookupConfig( XPAR_SCUGIC_SINGLE_DEVICE_ID );

	/* Sanity check the FreeRTOSConfig.h settings are correct for the
     * hardware. */
	configASSERT(pxGICConfig);
	configASSERT(pxGICConfig->CpuBaseAddress
                 == (configINTERRUPT_CONTROLLER_BASE_ADDRESS + configINTERRUPT_CONTROLLER_CPU_INTERFACE_OFFSET));
	configASSERT(pxGICConfig->DistBaseAddress
                 == configINTERRUPT_CONTROLLER_BASE_ADDRESS);

	/* Install a default handler for each GIC interrupt. */
    BaseType_t xStatus __attribute__((unused));
	xStatus = XScuGic_CfgInitialize(&xInterruptController, pxGICConfig, pxGICConfig->CpuBaseAddress);
	configASSERT(xStatus == XST_SUCCESS);

	/* The Xilinx projects use a BSP that do not allow the start up code to be
     * altered easily. Therefore the vector table used by FreeRTOS is defined in
     * FreeRTOS_asm_vectors.S, which is part of this project. Switch to use the
     * FreeRTOS vector table. */
	vPortInstallFreeRTOSVectorTable();

	/* Initialise UART for use with QEMU. */
	XUartPs_ResetHw(0xE0000000);
	XUartPs_WriteReg(0xE0000000, XUARTPS_CR_OFFSET,
                     ((u32)XUARTPS_CR_RX_DIS
                      | (u32)XUARTPS_CR_TX_EN
                      | (u32)XUARTPS_CR_STOPBRK));
}

__attribute__((weak))
void vInitialiseTimerForRunTimeStats( void )
{
    debug("vInitialiseTimerForRunTimeStats(): called\n");

    XScuWdt_Config *pxWatchDogInstance;
    uint32_t ulValue;
    const uint32_t ulMaxDivisor = 0xff, ulDivisorShift = 0x08;

    pxWatchDogInstance = XScuWdt_LookupConfig( XPAR_SCUWDT_0_DEVICE_ID );
    XScuWdt_CfgInitialize( &xWatchDogInstance, pxWatchDogInstance, pxWatchDogInstance->BaseAddr );

    ulValue = XScuWdt_GetControlReg( &xWatchDogInstance );
    ulValue |= ulMaxDivisor << ulDivisorShift;
    XScuWdt_SetControlReg( &xWatchDogInstance, ulValue );

    XScuWdt_LoadWdt( &xWatchDogInstance, UINT_MAX );
    XScuWdt_SetTimerMode( &xWatchDogInstance );
    XScuWdt_Start( &xWatchDogInstance );
}
