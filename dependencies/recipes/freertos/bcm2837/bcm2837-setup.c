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

#include <stdint.h>
#include <FreeRTOS.h>
#include <interrupts.h>

#define qa7reg(x) (*((volatile int32_t*)(((uintptr_t)(0x40000000))+(x))))

#define qa7route qa7reg(0x24)
#define qa7control qa7reg(0x34)
#define qa7clear qa7reg(0x38)
#define qa7c0control qa7reg(0x40)

#define qa7hz_to_cnt(x) (38400000/(x))
#define qa7control_timer_enable (1<<28)
#define qa7control_int_enable (1<<29)

#define qa7clear_int (1<<31)
#define qa7clear_cnt (1<<30)

#define qa7ccontrol_nCNTPSIRQ (1<<0)
#define qa7ccontrol_nCNTPNSIRQ (1<<1)
#define qa7ccontrol_nCNTPSIRQ_FIQ (1<<4)
#define qa7ccontrol_nCNTPNSIRQ_FIQ (1<<5)

int ulPortYieldRequired = 0;

__attribute__((no_instrument_function))
void vLocalTickISR()
{
	ulPortYieldRequired = xTaskIncrementTick();

	qa7clear = qa7clear_int;
}


void prvSetupLocalTimerInterrupt( void ) {
	qa7route = 0; // core 0
	qa7control = qa7hz_to_cnt(1000) | qa7control_timer_enable | qa7control_int_enable;

	qa7clear = qa7clear_int | qa7clear_cnt;

	qa7c0control &= ~qa7ccontrol_nCNTPNSIRQ_FIQ;
	qa7c0control |= qa7ccontrol_nCNTPNSIRQ;
}
/*-----------------------------------------------------------*/
