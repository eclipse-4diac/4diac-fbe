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

#include <FreeRTOS.h>
#include <semphr.h>
#include <task.h>
#include <sys/lock.h>
#include <sys/time.h>
#include <stdio.h>
#include <debug-printf.h>
#include <stdlib.h>


/* ********************************************************************* */
/* Overridable, semihosting-enabled default callbacks for FreeRTOS */

__attribute__((weak))
void vAssertCalled( const char * pcFile, unsigned long ulLine )
{
    taskENTER_CRITICAL_FROM_ISR();
    debug_printf("\n\n*** ASSERTION FAILED ***\n\n");
    debug_printf("Location: %s:%i\n", pcFile, ulLine);
    debug_print_backtrace();

    for (;;);
}

__attribute__((weak))
void vApplicationTickHook( void )
{
}

__attribute__((weak))
void vApplicationIdleHook( void )
{
}

__attribute__((weak))
void vApplicationStackOverflowHook( TaskHandle_t t, char *taskName )
{
    (void)t;
    taskENTER_CRITICAL_FROM_ISR();
    debug_printf("\n\n*** STACK OVERFLOW ***\n\n");
    debug_printf("Task: %s\n", taskName);
    debug_print_backtrace();

    for (;;);
}

__attribute__((weak))
void vApplicationMallocFailedHook( void )
{
    taskENTER_CRITICAL_FROM_ISR();
    debug_printf("\n\n*** MALLOC FAILED ***\n\n");
    debug_print_backtrace();

    for (;;);
}

/* if configUSE_STATIC_ALLOCATION is set to 1, the application must provide the
memory that is used by system tasks. */
__attribute__((weak))
void vApplicationGetIdleTaskMemory( StaticTask_t **ppxIdleTaskTCBBuffer, StackType_t **ppxIdleTaskStackBuffer, uint32_t *pulIdleTaskStackSize )
{
    static StaticTask_t xIdleTaskTCB;
    static StackType_t uxIdleTaskStack[ configMINIMAL_STACK_SIZE ];

	*ppxIdleTaskTCBBuffer = &xIdleTaskTCB;
	*ppxIdleTaskStackBuffer = uxIdleTaskStack;
	*pulIdleTaskStackSize = configMINIMAL_STACK_SIZE;
}

__attribute__((weak))
void vApplicationGetTimerTaskMemory( StaticTask_t **ppxTimerTaskTCBBuffer, StackType_t **ppxTimerTaskStackBuffer, uint32_t *pulTimerTaskStackSize )
{
    static StaticTask_t xTimerTaskTCB;
    static StackType_t uxTimerTaskStack[ configTIMER_TASK_STACK_DEPTH ];

	*ppxTimerTaskTCBBuffer = &xTimerTaskTCB;
	*ppxTimerTaskStackBuffer = uxTimerTaskStack;
	*pulTimerTaskStackSize = configTIMER_TASK_STACK_DEPTH;
}

// NOTE: assumes something like -DportCLEAN_UP_TCB="extern void vCleanUpTCB(void*); vCleanUpTCB"
__attribute__((weak))
void vCleanUpTCB(void *task) {
    extern void vTaskTLSFree(void *task);
    vTaskTLSFree(task);
}

__attribute__((weak))
BaseType_t xApplicationGetRandomNumber( uint32_t * pulNumber )
{
    *pulNumber = rand();
    return pdTRUE;
}

__attribute__((weak))
uint32_t ulApplicationGetNextSequenceNumber( uint32_t ulSourceAddress,
                                             uint16_t usSourcePort,
                                             uint32_t ulDestinationAddress,
                                             uint16_t usDestinationPort )
{
    ( void ) ulSourceAddress;
    ( void ) usSourcePort;
    ( void ) ulDestinationAddress;
    ( void ) usDestinationPort;
    // TODO: this could be more elaborate as per RFC 6528, but
    // it should be at least "cryptographically random"
    return rand();
}

__attribute__((weak))
void vApplicationFPUSafeIRQHandler( uint32_t ign ) {
    (void)ign;
}
