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
/* Debug output functions that should work as early as possible during the
 * lifetime of a bare metal program */

#ifndef __DEBUG_PRINTF_H_
#define __DEBUG_PRINTF_H_

#include <stdarg.h>
#include <stddef.h>

#ifdef DEBUG_SEMIHOSTING
#define QEMU_SEMIHOST_WRITEC 3
#define QEMU_SEMIHOST_WRITE0 4
#define debug_putc(ch) debug_semihost(QEMU_SEMIHOST_WRITEC, &(ch))
#define debug_puts(str) debug_semihost(QEMU_SEMIHOST_WRITE0, (str))
#define debug_init()

__attribute__((naked,no_instrument_function))
static int debug_semihost(int call, const char *ch) {

#if defined(__arm__)
    asm volatile(
#if __ARM_ARCH_PROFILE == 'M'
    "bkpt 0xab\n\t"
#elif defined(__thumb__)
    "svc 0xab\n\t"
#else
    "svc 0x123456\n\t"
#endif
    "bx lr\n\t"
    : : : "r0", "r1", "lr", "memory", "cc");

#elif defined(__riscv__)
    asm volatile(
        ".option push\n\t"
        ".option norvc\n\t"
        "slli zero, zero, 0x1f\n\t"
        "ebreak\n\t"
        "srai zero, zero, 0x7\n\t"
        "ret\n\t"
        ".option pop\n\t"
        : :
        : "a0", "a1", "memory", "cc");

#else
#error "No semihosting call known for this architecture."
#endif
}

#elif defined(DEBUG_RASPI_DIRECTHW_UART0)
#include <raspi-directhw/uart0.h>
#pragma GCC note "debug output might only work after uart0_init has been called"
#define debug_putc uart0_write
#define debug_init() uart0_init(115200)

#elif defined(DEBUG_RASPI_DIRECTHW_UART1)
#include <raspi-directhw/uart1.h>
#pragma GCC note "debug output might only work after uart1_init has been called"
#define debug_putc uart1_write
#define debug_init() uart1_init(115200)

#else
#define debug_putc(x) ERROR_You_need_to_choose_an_ouptut_method_for_debug_printf!
#endif

static inline void debug_printf_str(const char *msg) {
    static const char cr = '\r';
    while (*msg) {
        if (*msg == '\n') debug_putc(cr);
        debug_putc(*msg++);
    }
}

static inline void debug_printf_uint(unsigned n) {
	unsigned div = 1000000000ul;
	int started = 0;
	while (div > 1 && !(n/div)) div /= 10;
	while (div > 0) {
		char i = (n/div)%10 + '0';
		debug_putc(i);
		div /= 10;
	}
}

static inline void debug_printf_int(int n) {
    static const char minus = '-';
	if (n < 0) {
		debug_putc(minus);
		n = -n; // this yields wrong (but unique) output on n == INT_MIN
	}
	debug_printf_uint(n);
}

static inline void debug_printf_hex(unsigned n) {
	static const char *const hex = "0123456789abcdefx";
	debug_putc(hex[0]);
	debug_putc(hex[16]);
	debug_putc(hex[(n >> 28)&0xF]);
	debug_putc(hex[(n >> 24)&0xF]);
	debug_putc(hex[(n >> 20)&0xF]);
	debug_putc(hex[(n >> 16)&0xF]);
	debug_putc(hex[(n >> 12)&0xF]);
	debug_putc(hex[(n >> 8)&0xF]);
	debug_putc(hex[(n >> 4)&0xF]);
	debug_putc(hex[n&0xF]);
}

static inline void debug_vprintf(const char *msg, va_list var) {
    static const char cr = '\r';
	while (*msg) {
		if (*msg == '%') {
			char c, ch;
			do { // ignore modifier chars
				c = *++msg;
			} while (c == '.' || (c >= '0' && c <= '9') || c == ' ' || c == '-');
			switch (c) {
				case 's':
					debug_printf_str(va_arg(var, const char *));
					break;
				case 'i':
				case 'd':
					debug_printf_uint(va_arg(var, int));
					break;
				case 'u':
					debug_printf_uint(va_arg(var, unsigned));
					break;
				case 'c':
                    ch = va_arg(var, unsigned);
					debug_putc(ch);
					break;
                case 'X':
				case 'x':
				case 'p':
					debug_printf_hex(va_arg(var, unsigned));
					break;
				default:
					// hope for the best...
					va_arg(var, unsigned);
					debug_putc(msg[-1]);
					debug_putc(c);
			}
		} else {
			if (*msg == '\n') debug_putc(cr);
			debug_putc(*msg);
		}
		msg++;
	}
}

static inline void debug_printf(const char *msg, ...) {
	va_list var;
	va_start(var, msg);
    debug_vprintf(msg, var);
    va_end(var);
}

#ifdef DEBUG_BACKTRACE
// provided by libgcc, needs compiler flag -funwind-tables to work
#include <unwind.h>

static _Unwind_Reason_Code trace_fcn(_Unwind_Context *ctx, void *d)
{
    debug_printf("%p\n", _Unwind_GetIP(ctx));
    return _URC_NO_REASON;
}

// print a naively approximated call trace in case unwinding doesn't work well
static void debug_print_callers() {
    char **cur;
    cur = (char**)&cur;

    extern char __executable_start[], __etext[];
    char **stack_end = cur+0x2000; // blind guess
    debug_printf(" Potential Callers:\n");
    while (cur < stack_end) {
        if (*cur >= __executable_start && *cur < __etext) {
            debug_printf("%p\n", *cur);
        }
        cur++;
    }
    debug_printf(" Backtrace Callers:\n");
    _Unwind_Backtrace(&trace_fcn, NULL);
}

#ifdef __arm__
// finally, also print the LR register as a reliable source of our caller
#define debug_print_backtrace() do {                         \
        void* lr_content;                                \
        asm volatile ("mov %0, LR\n" : "=r" (lr_content) );  \
        debug_printf(" Caller = %p\n", lr_content);          \
        debug_print_callers();                                     \
    } while(0)
#else
#define debug_print_backtrace debug_print_callers
#endif


#else
#define debug_print_backtrace()
#endif

#endif
