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
#include <sys/lock.h>
#include <debug-printf.h>

/* ********************************************************************* */
/* Debugging support */

#define WARN_IRQ_MALLOC
//#define ALLOW_IRQ_MALLOC

#ifdef DEBUG_MALLOC
/* disable debugging output */
#define debug debug_printf
#else
#define debug(...)
#endif

/* ********************************************************************* */
/* generic locking primitives for newlib */

static uint32_t __malloc_lock_irqmask;

/* special-case malloc locking because of performance; TODO: check that there
 * actually is a performance gain */
void __malloc_lock() {
    debug("__malloc_lock(): called\n");

#ifdef WARN_IRQ_MALLOC
    if (!xTaskGetCurrentTaskHandle() && xTaskGetSchedulerState() != taskSCHEDULER_NOT_STARTED) {
        debug_printf("*** WARNING: MALLOC FROM ISR ***\n");
    }
#endif

#ifdef ALLOW_IRQ_MALLOC
    uint32_t oldmask = taskENTER_CRITICAL_FROM_ISR();
    __malloc_lock_irqmask = oldmask;
#else
    vTaskSuspendAll();
#endif
}

void __malloc_unlock() {
    debug("__malloc_unlock(): called\n");

#ifdef ALLOW_IRQ_MALLOC
    taskEXIT_CRITICAL_FROM_ISR(__malloc_lock_irqmask);
#else
    xTaskResumeAll();
#endif
}



/* requirements taken from newlib/libc/misc/lock.c; this code assumes that
 * (SemaphoreHandle_t) == (StaticSemaphore_t*), which is true at least for
 * now */
StaticSemaphore_t __lock___sinit_recursive_mutex;
StaticSemaphore_t __lock___sfp_recursive_mutex;
StaticSemaphore_t __lock___atexit_recursive_mutex;
StaticSemaphore_t __lock___at_quick_exit_mutex;
/* StaticSemaphore_t __lock___malloc_recursive_mutex; */
StaticSemaphore_t __lock___env_recursive_mutex;
StaticSemaphore_t __lock___tz_mutex;
StaticSemaphore_t __lock___dd_hash_mutex;
StaticSemaphore_t __lock___arc4random_mutex;

__attribute__((constructor))
void __init_retarget_locks(void)
{
    debug("<lock rec> init: sinit = %p\n", (uintptr_t)&__lock___sinit_recursive_mutex);
    xSemaphoreCreateRecursiveMutexStatic(&__lock___sinit_recursive_mutex);
    debug("<lock rec> init: sfp = %p\n", (uintptr_t)&__lock___sfp_recursive_mutex);
    xSemaphoreCreateRecursiveMutexStatic(&__lock___sfp_recursive_mutex);
    debug("<lock rec> init: atexit = %p\n", (uintptr_t)&__lock___atexit_recursive_mutex);
    xSemaphoreCreateRecursiveMutexStatic(&__lock___atexit_recursive_mutex);
    debug("<lock std> init: at_quick_exit = %p\n", (uintptr_t)&__lock___at_quick_exit_mutex);
    xSemaphoreCreateMutexStatic(&__lock___at_quick_exit_mutex);
    /* xSemaphoreCreateRecursiveMutexStatic(&__lock___malloc_recursive_mutex); */
    debug("<lock rec> init: env = %p\n", (uintptr_t)&__lock___env_recursive_mutex);
    xSemaphoreCreateRecursiveMutexStatic(&__lock___env_recursive_mutex);
    debug("<lock std> init: tz = %p\n", (uintptr_t)&__lock___tz_mutex);
    xSemaphoreCreateMutexStatic(&__lock___tz_mutex);
    debug("<lock std> init: dd_hash = %p\n", (uintptr_t)&__lock___dd_hash_mutex);
    xSemaphoreCreateMutexStatic(&__lock___dd_hash_mutex);
    debug("<lock std> init: arc4random = %p\n", (uintptr_t)&__lock___arc4random_mutex);
    xSemaphoreCreateMutexStatic(&__lock___arc4random_mutex);

}

void __retarget_lock_init(_LOCK_T *lock_ptr) {
    debug("<lock std> init: %p\n", (uintptr_t)*lock_ptr);
    *lock_ptr = (struct __lock *)xSemaphoreCreateMutex();
}


void __retarget_lock_init_recursive(_LOCK_T *lock_ptr) {
    debug("<lock rec> init: %p\n", (uintptr_t)*lock_ptr);
    *lock_ptr = (struct __lock *)xSemaphoreCreateRecursiveMutex();
}


void __retarget_lock_close(_LOCK_T lock) {
    debug("<lock std> close: %p\n", (uintptr_t)lock);
    vSemaphoreDelete((SemaphoreHandle_t)lock);
}


void __retarget_lock_close_recursive(_LOCK_T lock) {
    debug("<lock rec> close: %p\n", (uintptr_t)lock);
    vSemaphoreDelete((SemaphoreHandle_t)lock);
}


void __retarget_lock_acquire(_LOCK_T lock) {
    debug("<lock std> acquire: %p\n", (uintptr_t)lock);
    xSemaphoreTake((SemaphoreHandle_t)lock, portMAX_DELAY);
}


void __retarget_lock_acquire_recursive(_LOCK_T lock) {
    debug("<lock rec> acquire: %p\n", (uintptr_t)lock);
    xSemaphoreTakeRecursive((SemaphoreHandle_t)lock, portMAX_DELAY);
}


int __retarget_lock_try_acquire(_LOCK_T lock) {
    debug("<lock std> try-acquire: %p\n", (uintptr_t)lock);
    return xSemaphoreTake((SemaphoreHandle_t)lock, 0);
}


int __retarget_lock_try_acquire_recursive(_LOCK_T lock) {
    debug("<lock rec> try-acquire: %p\n", (uintptr_t)lock);
    return xSemaphoreTakeRecursive((SemaphoreHandle_t)lock, 0);
}


void __retarget_lock_release(_LOCK_T lock) {
    debug("<lock std> release: %p\n", (uintptr_t)lock);
    xSemaphoreGive((SemaphoreHandle_t)lock);
}


void __retarget_lock_release_recursive(_LOCK_T lock) {
    debug("<lock rec> release: %p\n", (uintptr_t)lock);
    xSemaphoreGiveRecursive((SemaphoreHandle_t)lock);
}
