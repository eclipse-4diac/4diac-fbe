// Taken from FreeRTOS: FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/*
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
#include <xuartps.h>
#include <xgpiops.h>
#include <timers.h>
#include <stdio.h>
#include <lwip/inet.h>
#include <lwip/tcpip.h>
#include <lwip/dhcp.h>
#include <debug-printf.h>

#define LWIP_PORT_INIT_IPADDR(addr)   IP4_ADDR((addr), configIP_ADDR0,configIP_ADDR1,configIP_ADDR2,configIP_ADDR3)
#define LWIP_PORT_INIT_GW(addr)       IP4_ADDR((addr), 192,168,0,3)
#define LWIP_PORT_INIT_NETMASK(addr)  IP4_ADDR((addr), 255,255,255,0)


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

static XGpioPs xGpio;

static void prvLEDToggleTimer(TimerHandle_t ign) {
	(void)ign;
	/* Just toggle an LED to show the application is running. */
	BaseType_t xLEDState = XGpioPs_ReadPin( &xGpio, partstLED_OUTPUT );
	XGpioPs_WritePin( &xGpio, partstLED_OUTPUT, !xLEDState );
}

static void prvLEDInitialise( void )
{
	/* Initialise the GPIO driver. */
	XGpioPs_Config *pxConfigPtr = XGpioPs_LookupConfig( XPAR_XGPIOPS_0_DEVICE_ID );
	BaseType_t xStatus = XGpioPs_CfgInitialize( &xGpio, pxConfigPtr, pxConfigPtr->BaseAddr );
	configASSERT( xStatus == XST_SUCCESS );
	( void ) xStatus; /* Remove compiler warning if configASSERT() is not defined. */

	/* Enable outputs and set low. */
	XGpioPs_SetDirectionPin( &xGpio, partstLED_OUTPUT, partstDIRECTION_OUTPUT );
	XGpioPs_SetOutputEnablePin( &xGpio, partstLED_OUTPUT, partstOUTPUT_ENABLED );
	XGpioPs_WritePin( &xGpio, partstLED_OUTPUT, 0x0 );
}

static int serial_putc(char c, FILE *ign) {
	(void)ign;
	static char buf[2] = { 0, 0 };
	outbyte(c);
	buf[0] = c;
	debug_printf(buf);
	return 0;
}

static int serial_getc(FILE *ign) {
	(void)ign;
	return inbyte();
}

static FILE serial_stdio = FDEV_SETUP_STREAM(serial_putc, serial_getc, NULL, _FDEV_SETUP_RW);

FILE *const __iob[3] = { &serial_stdio, &serial_stdio, &serial_stdio };

TimerHandle_t xTimer;

void prvSetupHardwareExtra(void) {
	/* Initialise the LED port. */
	prvLEDInitialise();

	/* A timer is used to toggle an LED just to show the application is executing. */
	xTimer = xTimerCreate("LED", 					/* Text name to make debugging easier. */
                          mainTIMER_PERIOD_MS, 	/* The timer's period. */
                          pdTRUE,					/* This is an auto reload timer. */
                          NULL,					/* ID is not used. */
                          prvLEDToggleTimer);	/* The callback function. */

	/* Start the timer. */
	configASSERT(xTimer);
	xTimerStart(xTimer, mainDONT_BLOCK);
}

void vStatusCallback( struct netif *pxNetIf )
{
	char pcMessage[20];
	struct in_addr* pxIPAddress;

        if( netif_is_up( pxNetIf ) != 0 ) {
                strcpy( pcMessage, "IP=" );
                pxIPAddress = ( struct in_addr* ) &( pxNetIf->ip_addr );
                printf( "IP=%s\n", inet_ntoa( ( *pxIPAddress ) ) );
        } else {
                printf( "Network is down\n" );
        }
}


/* Called from the TCP/IP thread. */
void lwIPInit(void *ign) {
	(void)ign;
    ip_addr_t xIPAddr, xNetMask, xGateway;
    extern err_t xemacpsif_init( struct netif *netif );
    extern void xemacif_input_thread( void *netif );
    static struct netif xNetIf;

	/* Set up the network interface. */
	ip_addr_set_zero( &xGateway );
	ip_addr_set_zero( &xIPAddr );
	ip_addr_set_zero( &xNetMask );

	LWIP_PORT_INIT_GW(&xGateway);
	LWIP_PORT_INIT_IPADDR( &xIPAddr );
	LWIP_PORT_INIT_NETMASK(&xNetMask);

	/* Set mac address */
	xNetIf.hwaddr_len = 6;
	xNetIf.hwaddr[ 0 ] = configMAC_ADDR0;
	xNetIf.hwaddr[ 1 ] = configMAC_ADDR1;
	xNetIf.hwaddr[ 2 ] = configMAC_ADDR2;
	xNetIf.hwaddr[ 3 ] = configMAC_ADDR3;
	xNetIf.hwaddr[ 4 ] = configMAC_ADDR4;
	xNetIf.hwaddr[ 5 ] = configMAC_ADDR5;

	netif_set_default( netif_add( &xNetIf, &xIPAddr, &xNetMask, &xGateway, ( void * ) XPAR_XEMACPS_0_BASEADDR, xemacpsif_init, tcpip_input ) );
	netif_set_status_callback( &xNetIf, vStatusCallback );

	#if LWIP_DHCP
    dhcp_start( &xNetIf );
	#else
    netif_set_up( &xNetIf );
	#endif

	sys_thread_new( "lwIP_In", xemacif_input_thread, &xNetIf, configMINIMAL_STACK_SIZE, configMAC_INPUT_TASK_PRIORITY );
}

void prvNetworkInit() {
	tcpip_init(lwIPInit, NULL);
}
