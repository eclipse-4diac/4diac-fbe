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

/* ********************************************************************* */
/* Thread-local storage support for picolibc TLS */

#include <stdint.h>
#include <FreeRTOS.h>
#include <task.h>
#include <picotls.h>

#ifdef DEBUG_TLS
#include <debug-printf.h>
#define debug(...) debug_printf(__VA_ARGS__)
#else
#define debug(...)
#endif

extern char __tdata_source[];
extern char __tdata_size[];
extern char __tbss_size[];

static void *prvTaskTLSInit() {
    void *tls = pvPortMalloc((uintptr_t)__tdata_size + (uintptr_t)__tbss_size);
    if (!tls) return __tdata_source;

    debug("init_task_tls(): success, block = %p\n", (intptr_t)tls);
    _init_tls(tls);
    vTaskSetThreadLocalStoragePointer(NULL, 0, tls);
    return tls;
}

// NOTE: the portRESTORE_CONTEXT macro/assembler function should call this
void vTaskTLSUpdate() {
    void *tls = pvTaskGetThreadLocalStoragePointer(NULL, 0);
    if (!tls) tls = prvTaskTLSInit();
    _set_tls(tls);
}

// NOTE: the portCLEAN_UP_TCB macro in portmacro.h should call this
void vTaskTLSFree(void *task) {
    void *tls = pvTaskGetThreadLocalStoragePointer(task, 0);
    if (!tls) return;

    debug("free_task_tls(): freeing tls block %p\n", (intptr_t)tls);
    /* TODO: Run destructors? */
    vPortFree(tls);
    vTaskSetThreadLocalStoragePointer(task, 0, NULL);
    vTaskTLSUpdate();
}

#if 0 /* ARM emulated TLS function, use with compiler flag -mtp=soft  */
void *__aeabi_read_tp() {
    TaskHandle_t task = xTaskGetCurrentTaskHandle();

    if (!task) {
        debug("*** TLS from ISR/init code has limited support! ***\n");
        return __tdata_source-8;
    }

    void *tls = pvTaskGetThreadLocalStoragePointer(task, 0);
    if (!tls) {
        prvTaskTLSInit();
        tls = pvTaskGetThreadLocalStoragePointer(task, 0);
    }

    if (!tls) {
        debug_printf("*** TLS allocation failed! ***\n");
        /* same hack as above, this time as emergency fallback */
        return __tdata_source-8;
    }

    return tls-8;
}
#endif
