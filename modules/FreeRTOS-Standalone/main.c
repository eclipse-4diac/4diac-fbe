// Partially based on FreeRTOS demo code
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
#include <arch/freeRTOS/forte_Init.h>
#include <task.h>
#include <stdio.h>

#include <debug-printf.h>

extern void prvNetworkInit();

// this function taken from https://www.eclipse.org/4diac/en_help.php?helppage=html/installation/freeRTOSLwIP.html
static void forte_thread(void *arg) {
  (void)arg;
  debug_printf("main(): setup tcpip\n");
  prvNetworkInit();

  debug_printf("Initializing FORTE...\n");
  forteGlobalInitialize();
  TForteInstance forteInstance = 0;

  debug_printf("Starting FORTE...\n");
  int resultForte = forteStartInstanceGeneric(0, 0, &forteInstance);
  if (resultForte == FORTE_OK) {
    forteJoinInstance(forteInstance);
  } else {
    debug_printf("Couldn't start forte, error = %i\n", resultForte);
  }

  debug_printf("Deinitializing FORTE...\n");
  forteGlobalDeinitialize();
  vTaskDelete(NULL);
}


extern void prvSetupHardwareExtra();

int main(void) {
  debug_printf("main(): setup hardware\n");
  prvSetupHardwareExtra();

  debug_printf("main(): setup task\n");
	xTaskCreate(forte_thread, "FORTE", configMINIMAL_STACK_SIZE, NULL, configMAX_PRIORITIES/2, NULL);
  debug_printf("main(): start scheduler\n");
	vTaskStartScheduler();
  debug_printf("main(): infinite loop\n");
  for(;;){}
}
