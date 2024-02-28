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

/*
 * This file contains code from picolibc
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright © 2019 Keith Packard
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include <sys/lock.h>
#include <sys/time.h>
#include <stdio.h>
#include <string.h>
#include <debug-printf.h>
#include <sys/types.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>

#ifdef DEBUG_NEWLIB
#define debug(...) debug_printf(__VA_ARGS__)
#else
#define debug(...)
#endif

/* ********************************************************************* */
/* device-specific newlib functions overridable by the BSP */

__attribute__((weak))
FILE *fopen(const char *file, const char *mode) {
    (void)file; (void)mode;
    debug("fopen(): unimplemented\n");
    return NULL;
}

__attribute__((weak))
ssize_t write(int fd, const void *buf, size_t len) {
    if (fd >= 0 && fd <= 2) {
        ssize_t ret = len;
        while (len--) debug_putc(*(const char *)buf++);
        return ret;
    }
	return -1;
}

__attribute__((weak))
int gettimeofday(struct timeval *tm, void *tz) {
    (void)tz;
    debug("gettimeofday(): unimplemented\n");
    memset(tm, 0, sizeof(*tm));
    return 0;
}

__attribute__((weak))
pid_t getpid(void) {
    return 1;
}

__attribute__((weak))
int kill(pid_t pid, int sig) {
    if (pid == 1) _exit(sig << 8);
    errno = ESRCH;
    return -1;
}

__attribute__((weak,noreturn))
void _exit(int code) {
    debug_printf("\n\n*** EXIT CALLED WITH EXIT CODE %i ***\n\n", code);
    for (;;);
}

/* ********************************************************************* */
/* functions wanted by newlib on some platforms */
__attribute__((weak))
void _init() {
    debug("_init(): called\n");
}
__attribute__((weak))
void _fini() {
    debug("_fini(): called\n");
}


/* ********************************************************************* */
/* startup function that don't mess with processor state */

#include <string.h>
#include <picotls.h>
#include <stdint.h>

extern char __data_source[];
extern char __data_start[];
extern char __data_size[];
extern char __bss_start[];
extern char __bss_size[];
extern char __tls_base[];

extern int main(int, char **);
extern void __libc_init_array(void);
extern void __libc_fini_array(void);

__attribute__((weak)) __section(".init")
void _start(void)
{
    debug_init();
    debug("_start(): called\n");

	//memcpy(__data_start, __data_source, (uintptr_t) __data_size);
	memset(__bss_start, '\0', (uintptr_t) __bss_size);
	_set_tls(__tls_base);
	__libc_init_array();
	int ret = main(0, NULL);
	__libc_fini_array();
    _exit(ret);
}
