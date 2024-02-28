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
/* Adapted from FreeRTOS/Source/portable/heap_3.c
 * FreeRTOS Kernel V10.4.3
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
 * https://www.FreeRTOS.org
 * https://github.com/FreeRTOS
 */

#include <malloc.h>
#include <FreeRTOS.h>

// remove locking here because newlib does its own locking
void *pvPortMalloc(size_t xWantedSize)
{
    void *pvReturn;

    pvReturn = malloc(xWantedSize);
    traceMALLOC(pvReturn, xWantedSize);

#if configUSE_MALLOC_FAILED_HOOK
    if (!pvReturn) {
        extern void vApplicationMallocFailedHook( void );
        vApplicationMallocFailedHook();
    }
#endif

    return pvReturn;
}

void vPortFree(void *pv) {
    if (pv) {
        free(pv);
        traceFREE(pv, 0);
    }
}

extern char __heap_start[];
extern char __heap_end[];

// assumes no one else is calling sbrk
size_t xPortGetFreeHeapSize() {
    size_t heap_size = __heap_end - __heap_start;
    struct mallinfo info = mallinfo();
    size_t heap_free = heap_size - info.arena;
    return info.fordblks + heap_free;
}

// this is an incorrect but probably 'good enough' approximation
size_t xPortGetMinimumEverFreeHeapSize() {
    size_t heap_size = __heap_end - __heap_start;
    struct mallinfo info = mallinfo();
    return heap_size - info.arena;
}
