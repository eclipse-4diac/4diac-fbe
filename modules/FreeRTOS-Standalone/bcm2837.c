// Taken from https://github.com/rooperl/RaspberryPi-FreeRTOS/blob/rasp3/Demo/main.c
// Authored by Jared Hull
// Modified by Roope Lindstrom & Emil Pirinen
// Contains parts of:
/*
 * FreeRTOS V202012.00
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
 *
 * 1 tab == 4 spaces!
 */

#include <FreeRTOS.h>
#include <task.h>
#include <FreeRTOS_IP.h>
#include <FreeRTOS_Sockets.h>
#include <timers.h>
#include <stdio.h>
#include <debug-printf.h>
#include <raspi-directhw/uart1.h>

/* The rate at which data is sent to the queue.  The 200ms value is converted
to ticks using the portTICK_PERIOD_MS constant. */
#define mainTIMER_PERIOD_MS			( 200 / portTICK_PERIOD_MS )

/* The LED toggled by the Rx task. */
#define mainTIMER_LED				( 0 )

/* A block time of zero just means "don't block". */
#define mainDONT_BLOCK				( 0 )

#define partstLED_OUTPUT                ( 10 ) /* Change to 47 for MicroZed, 10 for ZC702 */
#define partstDIRECTION_OUTPUT  ( 1 )
#define partstOUTPUT_ENABLED    ( 1 )

int serial_putc(char c, FILE *ign) {
	(void)ign;
	debug_putc(c);
	return 0;
}

static int serial_getc(FILE *ign) {
	(void)ign;
	return EOF;
}

static FILE serial_stdio = FDEV_SETUP_STREAM(serial_putc, serial_getc, NULL, _FDEV_SETUP_RW);

FILE *const __iob[3] = { &serial_stdio, &serial_stdio, &serial_stdio };

void prvSetupHardwareExtra(void) {
	debug_printf("extra HW init\n");
}


void prvNetworkInit() {
/*	static const unsigned char ucIPAddress[ 4 ] = { 10, 14, 99, 100 }; // just in case DHCP is not configured
	static const unsigned char ucNetMask[ 4 ] = { 255, 255, 255, 0 };
	static const unsigned char ucGatewayAddress[ 4 ] = { 10, 14, 99, 1 };
	static const unsigned char ucDNSServerAddress[ 4 ] = { 10, 14, 99, 1 };
	static const unsigned char ucMACAddress[ 6 ] = { 0, 0, 0, 0, 0, 0 };
	debug_printf("ip init\n");
	FreeRTOS_IPInit(ucIPAddress, ucNetMask, ucGatewayAddress, ucDNSServerAddress, ucMACAddress);
	debug_printf("ip init done\n");
    */
}
