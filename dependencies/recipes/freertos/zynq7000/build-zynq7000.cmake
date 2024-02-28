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


if (NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "arm")
  message(FATAL_ERROR "This platform needs an ARM toolchain")
endif()
string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
set(FLAGS " ${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${BUILD_TYPE}} ")
if (FLAGS MATCHES " -mcpu=cortex-a9 " AND FLAGS MATCHES " -mfpu=vfpv3 " AND FLAGS MATCHES " -mthumb ")
  # all is fine
else()
  message(FATAL_ERROR "This platform needs compiler flags -mcpu=cortex-a9 -mfpu=vfpv3 -mthumb")
endif()

set(ZYNQ7000_dir "${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo_bsp/ps7_cortexa9_0")

patch_diff("${CMAKE_CURRENT_SOURCE_DIR}" "${CGET_RECIPE_DIR}/zynq7000/freertos.diff")


##############################################################################
# prepare include directory
file(GLOB ZYNQ7000_includes CONFIGURE_DEPENDS "${ZYNQ7000_dir}/libsrc/*/src/*.h")
file(COPY ${ZYNQ7000_includes} DESTINATION "${ZYNQ7000_dir}/include")

#  qemu-semihosting-based print function for debugging purposes
file(COPY "${CGET_RECIPE_DIR}/common/debug-printf.h" DESTINATION "${ZYNQ7000_dir}/include")


##############################################################################
# The Zynq BSP works as oslib for picolibc
find_package(picolibc REQUIRED)

# the actual library, but this must not be linked against, because using it
# without an appropriate specs file (see below) breaks linking
freertos_autosrc(zynq7000-sys
  "${CGET_RECIPE_DIR}/common/newlib-syscalls.c"
  "${ZYNQ7000_dir}/libsrc/*/src/*.[cS]")
# remove files that conflict with picolibc or are plain duplicates
list(REMOVE_ITEM zynq7000-sys "${ZYNQ7000_dir}/libsrc/standalone_v6_6/src/errno.c")
list(REMOVE_ITEM zynq7000-sys "${ZYNQ7000_dir}/libsrc/standalone_v6_6/src/sbrk.c")
add_library(zynq7000-sys STATIC ${zynq7000-sys})
target_link_libraries(zynq7000-sys PRIVATE picolibc::picolibc)
target_compile_definitions(zynq7000-sys PUBLIC DEBUG_SEMIHOSTING DEBUG_TLS DEBUG_NEWLIB DEBUG_MALLOC)
target_compile_definitions(zynq7000-sys PUBLIC DEBUG_BACKTRACE)
target_include_directories(zynq7000-sys PRIVATE
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src"
  "${ZYNQ7000_dir}/include")

# interface library that provides the correct specs file
add_library(zynq7000-os INTERFACE)
add_dependencies(zynq7000-os zynq7000-sys)
target_compile_definitions(zynq7000-os INTERFACE DEBUG_SEMIHOSTING DEBUG_NEWLIB)
target_compile_definitions(zynq7000-os INTERFACE DEBUG_BACKTRACE)
target_compile_options(zynq7000-os INTERFACE
  $<BUILD_INTERFACE:-specs=${CMAKE_CURRENT_SOURCE_DIR}/zynq7000.specs>
  $<INSTALL_INTERFACE:-specs=${CMAKE_INSTALL_PREFIX}/lib/zynq7000.specs>
  )
target_link_options(zynq7000-os INTERFACE
  #-v
  #-Wl,--verbose
  $<BUILD_INTERFACE:-L${CMAKE_CURRENT_BINARY_DIR}>
  $<BUILD_INTERFACE:-L${CGET_RECIPE_DIR}/zynq7000> # for ld script
  $<BUILD_INTERFACE:-specs=${CMAKE_CURRENT_SOURCE_DIR}/zynq7000.specs>
  $<INSTALL_INTERFACE:-specs=${CMAKE_INSTALL_PREFIX}/lib/zynq7000.specs>
  )
target_include_directories(zynq7000-os INTERFACE
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Source/include>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Source/portable/GCC/ARM_CA9>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src>"
  "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/FreeRTOS>"
  "$<BUILD_INTERFACE:${ZYNQ7000_dir}/include>"
  "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/zynq7000>")

install(FILES ${CGET_RECIPE_DIR}/zynq7000/zynq7000.ld DESTINATION lib)

file(WRITE "zynq7000.specs"
  "%include <${CMAKE_INSTALL_PREFIX}/lib/picolibc/picolibcpp.specs>\n"
  "\n"
  "*cc1:\n"
  "+ -isystem ${CMAKE_INSTALL_PREFIX}/include/picolibc\n"
  "\n"
  "*cc1plus:\n"
  "-isystem ${CMAKE_INSTALL_PREFIX}/include/picolibc %{!ftls-model:-ftls-model=local-exec} %(picolibc_cc1plus)\n"  # undo nonfunctional picolibc config
  "\n"
  "*cpp:\n"
  "+ -isystem ${CMAKE_INSTALL_PREFIX}/include/picolibc -DRASPI_DIRECTHW_PI23_ONLY\n"
  "\n"
  "*link:\n"
  "+ -L${CMAKE_INSTALL_PREFIX}/lib %{-heap-size=*:--defsym=_HEAP_SIZE=%*}\n" # 64MB
  "\n"
  "*lib:\n"
  "-Tzynq7000.ld --undefined=_boot --start-group %G -lzynq7000-sys -lc --end-group\n"
  "\n"
  "*startfile:\n"
  "crtbegin%O%s\n" # do not use picolibc start file
  "\n"
  )

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/zynq7000.specs
  DESTINATION lib)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/FreeRTOSConfig.h
  DESTINATION include/zynq7000)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Source/portable/GCC/ARM_CA9/portmacro.h
  DESTINATION include/zynq7000)

install(DIRECTORY ${ZYNQ7000_dir}/include/.
  DESTINATION include/zynq7000)

##############################################################################
# freertos-specific platform library
freertos_autosrc(freertos-platform
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/FreeRTOS_tick_config.c"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/FreeRTOS_asm_vectors.S"
  "FreeRTOS/Source/portable/GCC/ARM_CA9"
  "${CGET_RECIPE_DIR}/common/freertos-hooks.c"
  "${CGET_RECIPE_DIR}/common/tls-support.c"
  "${CGET_RECIPE_DIR}/zynq7000/zynq-setup.c"
  "${CGET_RECIPE_DIR}/common/lock.c")
add_library(freertos-platform STATIC ${freertos-platform})
target_compile_definitions(freertos-platform INTERFACE "portCLEAN_UP_TCB=vCleanUpTCB")
target_link_options(freertos-platform INTERFACE -Wl,--undefined=__init_retarget_locks)
target_link_options(freertos-platform INTERFACE -Wl,--undefined=vSetupHardware)
target_link_libraries(freertos-platform PUBLIC zynq7000-os)
target_include_directories(freertos-platform PRIVATE
  "FreeRTOS/Source/portable/GCC/ARM_CA9"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src")


##############################################################################
# lwip-specific platform library
freertos_autosrc(freertos-lwip-platform
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwIP_Demo/lwIP_port"
  "FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwIP_Demo/lwIP_port/netif")
add_library(freertos-lwip-platform STATIC ${freertos-lwip-platform})
target_link_libraries(freertos-lwip-platform PUBLIC freertos-platform)
target_include_directories(freertos-lwip-platform PRIVATE
  "FreeRTOS/Demo/Common/ethernet/lwip-1.4.0/src/include"
  "FreeRTOS/Demo/Common/ethernet/lwip-1.4.0/src/include/ipv4")
target_include_directories(freertos-lwip-platform PUBLIC
  "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/zynq7000/lwip>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwIP_Demo/lwIP_port/include>")

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwIP_Demo/lwIP_port/include/.
  DESTINATION include/zynq7000/lwip)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/CORTEX_A9_Zynq_ZC702/RTOSDemo/src/lwipopts.h
  DESTINATION include/zynq7000/lwip)

set(LWIP 1)

##############################################################################
#install(FILES force_error_exit DESTINATION .)
install(TARGETS zynq7000-sys zynq7000-os freertos-platform freertos-lwip-platform
  EXPORT freertos
  DESTINATION lib)
