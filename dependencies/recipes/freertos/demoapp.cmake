#********************************************************************************
# Copyright (c) 2018, 2024 OFFIS e.V.
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
#

if (FREERTOS_CONFIG STREQUAL "zynq7000")
freertos_autosrc(freertos-platform-demo-full
  "FreeRTOS/Demo/Common/Minimal"
  "FreeRTOS-Plus/Demo/Common/FreeRTOS_Plus_CLI_Demos/Sample-CLI-commands.c"
  "FreeRTOS-Plus/Demo/Common/FreeRTOS_Plus_CLI_Demos/UARTCommandConsole.c"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/ParTest.c"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/Full_Demo")
add_library(freertos-platform-demo-full STATIC ${freertos-platform-demo-full})
target_link_libraries(freertos-platform-demo-full PUBLIC
  freertos-core freertos-platform freertos-plus-cli m)
target_include_directories(freertos-platform-demo-full PUBLIC
  "FreeRTOS/Demo/Common/include"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/Full_Demo")


freertos_autosrc(freertos-platform-demo-blinky
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/ParTest.c"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/Blinky_Demo")
add_library(freertos-platform-demo-blinky STATIC ${freertos-platform-demo-blinky})
target_link_libraries(freertos-platform-demo-blinky PUBLIC freertos-core)
target_include_directories(freertos-platform-demo-blinky PUBLIC
  "FreeRTOS/Demo/Common/include")


freertos_autosrc(freertos-platform-demo-lwip
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwIP_Demo/lwIP_Apps/apps/httpserver_raw_from_lwIP_download"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwIP_Demo/lwIP_Apps/apps/BasicSocketCommandServer"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwIP_Demo/lwIP_Apps"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/ParTest.c"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwIP_Demo")
add_library(freertos-platform-demo-lwip STATIC ${freertos-platform-demo-lwip})
target_link_libraries(freertos-platform-demo-lwip PUBLIC
  freertos-platform-demo-full freertos-lwip)
target_compile_definitions(freertos-platform-demo-lwip PRIVATE LWIP_HTTPD_STRNSTR_PRIVATE=0)


add_executable(demo_full.elf
  FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/main.c)
target_compile_definitions(demo_full.elf PRIVATE mainSELECTED_APPLICATION=1 vAssertCalled=unusedXXX)
target_link_libraries(demo_full.elf freertos-platform-demo-full)

add_executable(demo_blinky.elf
  FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/main.c)
target_compile_definitions(demo_blinky.elf PRIVATE mainSELECTED_APPLICATION=0 vAssertCalled=unusedXXX)
target_link_libraries(demo_blinky.elf freertos-platform-demo-blinky)

add_executable(demo_lwip.elf
  FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/main.c)
target_compile_definitions(demo_lwip.elf PRIVATE mainSELECTED_APPLICATION=2 vAssertCalled=unusedXXX)
target_link_libraries(demo_lwip.elf freertos-platform-demo-lwip)

install(TARGETS demo_full.elf demo_blinky.elf
  demo_lwip.elf
  DESTINATION bin)

endif()
