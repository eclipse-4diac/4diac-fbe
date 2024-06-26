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
if (FLAGS MATCHES "-mcpu=cortex-a7" AND FLAGS MATCHES "-mfpu=vfpv3" AND FLAGS MATCHES "-mthumb")
  # all is fine
else()
  message(FATAL_ERROR "This platform needs compiler flags -mcpu=cortex-a7 -mfpu=vfpv3 -mthumb")
endif()

##############################################################################
# prepare external source

set(BCM2837_dir "${CMAKE_CURRENT_SOURCE_DIR}/rasp3")

add_source("${BCM2837_dir}" rasp3.zip
  https://github.com/rooperl/RaspberryPi-FreeRTOS/archive/5dc0701f5ab5202420650f12cba2d54e7010033e.zip
  6b549304887f2895b1cc025cb3f0f037d75fc89038a63ef0880e2c2ba8ff305c)

patch_diff("${BCM2837_dir}" "${CGET_RECIPE_DIR}/bcm2837/raspi3.diff")

# also include a lightweight hardware access library
add_source("${BCM2837_dir}/Drivers/lan9514/include/raspi-directhw" raspi-directhw.zip
  https://github.com/offis/raspi-directhw/archive/1d88f96385aee73c1e5147134c814d247c92c5a5.zip
  443e41abedc42e0feb8a182ba816d5f0d56d6ef7bbdd3f45e4d5282bc93d9a9d)


##############################################################################
# prepare include directory, reuse lan9514 dir as the repo has no dedicated dir
file(GLOB BCM2837_includes CONFIGURE_DEPENDS "${BCM2837_dir}/Drivers/*.h")
file(COPY ${BCM2837_includes} DESTINATION "${BCM2837_dir}/Drivers/lan9514/include")

#  qemu-semihosting-based print function for debugging purposes
file(COPY "${CGET_RECIPE_DIR}/common/debug-printf.h" DESTINATION "${BCM2837_dir}/Drivers/lan9514/include")


##############################################################################
# Use dummy oslib for picolibc
find_package(picolibc REQUIRED)

# the actual library, but this must not be linked against, because using it
# without an appropriate specs file (see below) breaks linking
freertos_autosrc(bcm2837-sys
  "${CGET_RECIPE_DIR}/common/newlib-syscalls.c"
  # FIXME: this doesn't work right now
  #"${BCM2837_dir}/Drivers/lan9514/uspibind.c"
  "${BCM2837_dir}/Drivers/video.c"
  "${BCM2837_dir}/Drivers/interrupts.c"
  "${BCM2837_dir}/Drivers/mailbox.c"
  #"${BCM2837_dir}/Drivers/lan9514/lib/*.c"
  )
add_library(bcm2837-sys STATIC ${bcm2837-sys})
target_link_libraries(bcm2837-sys PRIVATE picolibc::picolibc)
target_compile_definitions(bcm2837-sys PRIVATE memcpy2=memcpy RASPI_DIRECTHW_PI23_ONLY)
target_compile_definitions(bcm2837-sys PUBLIC DEBUG_RASPI_DIRECTHW_UART1)
#target_compile_definitions(bcm2837-sys PUBLIC DEBUG_SEMIHOSTING)
target_compile_definitions(bcm2837-sys PUBLIC DEBUG_BACKTRACE)
target_compile_definitions(bcm2837-sys PUBLIC DEBUG_TLS)
target_compile_definitions(bcm2837-sys PUBLIC DEBUG_MALLOC)
target_compile_definitions(bcm2837-sys PUBLIC DEBUG_NEWLIB)
target_include_directories(bcm2837-sys PRIVATE "${BCM2837_dir}/Drivers/lan9514/include")

# interface library that provides the correct specs file
add_library(bcm2837-os INTERFACE)
add_dependencies(bcm2837-os bcm2837-sys)
target_compile_definitions(bcm2837-os INTERFACE DEBUG_RASPI_DIRECTHW_UART1)
#target_compile_definitions(bcm2837-os INTERFACE DEBUG_SEMIHOSTING)
target_compile_definitions(bcm2837-os INTERFACE DEBUG_BACKTRACE)
#target_compile_definitions(bcm2837-os INTERFACE DEBUG_TLS)
#target_compile_definitions(bcm2837-os INTERFACE DEBUG_MALLOC)
target_compile_definitions(bcm2837-os INTERFACE DEBUG_NEWLIB)
target_compile_options(bcm2837-os INTERFACE
  $<BUILD_INTERFACE:-specs=${CMAKE_CURRENT_SOURCE_DIR}/bcm2837.specs>
  $<INSTALL_INTERFACE:-specs=${CMAKE_INSTALL_PREFIX}/lib/bcm2837.specs>
  )
target_link_options(bcm2837-os INTERFACE
  #-v
  #-Wl,--verbose
  $<BUILD_INTERFACE:-L${CMAKE_CURRENT_BINARY_DIR}>
  $<BUILD_INTERFACE:-L${CGET_RECIPE_DIR}/bcm2837> # for ld script
  $<BUILD_INTERFACE:-specs=${CMAKE_CURRENT_SOURCE_DIR}/bcm2837.specs>
  $<INSTALL_INTERFACE:-specs=${CMAKE_INSTALL_PREFIX}/lib/bcm2837.specs>
  )

target_include_directories(bcm2837-os INTERFACE
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Source/include>"
  "$<BUILD_INTERFACE:${BCM2837_dir}/FreeRTOS/Source/portable/GCC/RaspberryPi>"
  "$<BUILD_INTERFACE:${BCM2837_dir}/FreeRTOS/Source/include>"
  "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/FreeRTOS>"
  "$<BUILD_INTERFACE:${BCM2837_dir}/Drivers/lan9514/include>"
  "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/bcm2837>")

install(FILES ${CGET_RECIPE_DIR}/bcm2837/bcm2837.ld DESTINATION lib)

file(WRITE "bcm2837.specs"
  "%include <${CMAKE_INSTALL_PREFIX}/lib/picolibc/picolibcpp.specs>\n"
  "\n"
  "*cc1:\n"
  "+ -isystem ${CMAKE_INSTALL_PREFIX}/include/picolibc -DRASPI_DIRECTHW_PI23_ONLY\n"
  "\n"
  "*cc1plus:\n"
  "-isystem ${CMAKE_INSTALL_PREFIX}/include/picolibc -DRASPI_DIRECTHW_PI23_ONLY %{!ftls-model:-ftls-model=local-exec} %(picolibc_cc1plus)\n"  # undo nonfunctional picolibc config
  "\n"
  "*cpp:\n"
  "+ -isystem ${CMAKE_INSTALL_PREFIX}/include/picolibc -DRASPI_DIRECTHW_PI23_ONLY\n"
  "\n"
  "*link:\n"
  "+ -L${CMAKE_INSTALL_PREFIX}/lib %{-heap-size=*:--defsym=_HEAP_SIZE=%*}\n" # 64MB
  "\n"
  "*lib:\n"
  "-Tbcm2837.ld --undefined=_boot --start-group %G -lbcm2837-sys -lc --end-group\n"
  "\n"
  "*startfile:\n"
  "crtbegin%O%s\n" # do not use picolibc start file
  "\n"
  )

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/bcm2837.specs
  DESTINATION lib)

install(FILES ${BCM2837_dir}/FreeRTOS/Source/include/FreeRTOSConfig.h
  DESTINATION include/bcm2837)

install(FILES ${BCM2837_dir}/FreeRTOS/Source/portable/GCC/RaspberryPi/portmacro.h
  DESTINATION include/bcm2837)

install(DIRECTORY ${BCM2837_dir}/Drivers/lan9514/include/.
  DESTINATION include/bcm2837)

##############################################################################
# freertos-specific platform library
freertos_autosrc(freertos-platform
  "${CGET_RECIPE_DIR}/bcm2837/startup.s"
  "${BCM2837_dir}/FreeRTOS/Source/portable/GCC/RaspberryPi"
  "${CGET_RECIPE_DIR}/common/freertos-hooks.c"
  "${CGET_RECIPE_DIR}/common/tls-support.c"
  "${CGET_RECIPE_DIR}/bcm2837/bcm2837-setup.c"
  "${CGET_RECIPE_DIR}/bcm2837/portASM.S"
  "${CGET_RECIPE_DIR}/common/lock.c")
add_library(freertos-platform STATIC ${freertos-platform})
target_link_options(freertos-platform INTERFACE -Wl,--undefined=__init_retarget_locks)
target_link_options(freertos-platform INTERFACE -Wl,--undefined=vSetupHardware)
target_link_libraries(freertos-platform PUBLIC bcm2837-os)

##############################################################################
# FreeRTOS+TCP-specific platform library
freertos_autosrc(freertos-plus-tcp-platform
  "${BCM2837_dir}/Drivers/FreeRTOS-Plus-TCP/portable/NetworkInterface.c")
add_library(freertos-plus-tcp-platform STATIC ${freertos-plus-tcp-platform})
target_link_libraries(freertos-plus-tcp-platform PUBLIC freertos-platform)
target_include_directories(freertos-plus-tcp-platform PRIVATE
  "${BCM2837_dir}/Drivers/lan9514/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Plus/Source/FreeRTOS-Plus-TCP/include"
  "${BCM2837_dir}/Drivers/FreeRTOS-Plus-TCP/include")
target_include_directories(freertos-plus-tcp-platform PUBLIC
  "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/bcm2837>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Plus/Source/FreeRTOS-Plus-TCP/include>"
  "$<BUILD_INTERFACE:${BCM2837_dir}/Drivers/FreeRTOS-Plus-TCP/include>")

install(FILES ${BCM2837_dir}/Drivers/FreeRTOS-Plus-TCP/include/FreeRTOSIPConfig.h
  DESTINATION include/bcm2837)

set(TCP 1)

##############################################################################
#install(FILES force_error_exit DESTINATION .)
install(TARGETS bcm2837-sys bcm2837-os freertos-platform freertos-plus-tcp-platform
  EXPORT freertos
  DESTINATION lib)
