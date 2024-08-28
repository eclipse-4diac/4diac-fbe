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

project(FORTE CXX)
cmake_minimum_required(VERSION 3.12)
include(toolchain-utils)

#############################################################################
# Build Type
#

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "")
endif()

patch("src/arch/posix/main.cpp" "  startupHook" "  fbe_startupHook")

if (FORTE_ARCHITECTURE STREQUAL "FreeRTOSLwIP")
  add_definitions("-Dfbe_startupHook=startupHook")
  find_package(freertos)
  set(FORTE_BUILD_EXECUTABLE OFF CACHE BOOL "" FORCE)
  set(FORTE_BUILD_STATIC_LIBRARY ON CACHE BOOL "" FORCE)
elseif (TOOLCHAIN_ABI MATCHES "gnu")
  add_definitions("\"-Dfbe_startupHook(x,y)=if (getenv(\\\"FORTE_RUNDIR\\\")) { chdir(getenv(\\\"FORTE_RUNDIR\\\")); unsetenv(\\\"FORTE_RUNDIR\\\"); } startupHook(x,y)\"")
  set(FORTE_ARCHITECTURE "Posix" CACHE STRING "")
elseif (UNIX)
  add_definitions("-Dfbe_startupHook=startupHook")
  set(FORTE_ARCHITECTURE "Posix" CACHE STRING "")
elseif (WIN32)
  add_definitions("-Dfbe_startupHook=startupHook")
  set(FORTE_ARCHITECTURE "Win32" CACHE STRING "")
  set(FORTE_WINDOWS_XP_COMPAT ON CACHE BOOL "")
else ()
  add_definitions("-Dfbe_startupHook=startupHook")
  message(FATAL_ERROR "Unsupported target operating system.")
endif ()

add_compile_options("-Wall" "-Wextra")
add_compile_options("-Wno-overloaded-virtual")
add_compile_options("-fdiagnostics-color=always")
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "")
  #add_compile_options("-Werror")
  # these may occur in generated code, so demote them to warnings
  add_compile_options("-Wno-error=int-in-bool-context")
  add_compile_options("-Wno-error=conversion")
  add_compile_options("-Wno-error=float-conversion")
  add_compile_options("-Wno-error=sign-conversion")
  add_compile_options("-Wno-error=unused-parameter")
  add_compile_options("-Wno-error=parentheses")
else ()
  add_compile_options("-Wno-int-in-bool-context" "-Wno-conversion" "-Wno-float-conversion")
  add_compile_options("-Wno-unused-parameter")
endif ()

# reset defaults to "no modules enabled"
set(FORTE_COM_ETH OFF CACHE BOOL "")
set(FORTE_COM_FBDK OFF CACHE BOOL "")
set(FORTE_COM_RAW OFF CACHE BOOL "")
set(FORTE_MODULE_UTILS OFF CACHE BOOL "")
set(FORTE_MODULE_CONVERT OFF CACHE BOOL "")
set(FORTE_MODULE_IEC61131 OFF CACHE BOOL "")
set(FORTE_MODULE_CUSTOM_FBS OFF CACHE BOOL "")

#############################################################################
# Library Paths for the build system
#

set(FORTE_EXTERNAL_MODULES_DIRECTORY "${CGET_PREFIX}/../../Modules" CACHE STRING "")

if (FORTE_COM_PAHOMQTT)
  set(FORTE_COM_PAHOMQTT_INCLUDE_DIR "${CGET_PREFIX}/include" CACHE STRING "")
  set(FORTE_COM_PAHOMQTT_LIB "paho-mqtt3as" CACHE STRING "")
  link_libraries(${FORTE_COM_PAHOMQTT_LIB})
endif()

if (FORTE_COM_MODBUS)
  set(FORTE_COM_MODBUS_LIB_DIR "${CGET_PREFIX}" CACHE STRING "")
  add_compile_options("-I${CMAKE_CURRENT_SOURCE_DIR}/src/com/modbus")
endif ()

if (FORTE_MODULE_POWERLINK)
  find_library(POWERLINK powerlink REQUIRED)
  set(FORTE_MODULE_POWERLINK_LIB_DIR "${CGET_PREFIX}/src/openpowerlink" CACHE STRING "")
  set(FORTE_MODULE_POWERLINK_TINYXML_DIR "${CGET_PREFIX}/src/tinyxml" CACHE STRING "")
  # the tinyxml dependency violates these
  add_compile_options("-Wno-error=shadow")
  add_compile_options("-Wno-error=implicit-fallthrough")
  # openpowerlink itself violates this on some compilers+64bit-ness
  add_compile_options("-Wno-error=format=")
endif ()

if (FORTE_COM_OPC_UA)
  set(FORTE_COM_OPC_UA_INCLUDE_DIR "${CGET_PREFIX}/include" CACHE STRING "")
  set(FORTE_COM_OPC_UA_LIB "${CGET_PREFIX}/lib/libopen62541.a" CACHE STRING "")
  set(FORTE_COM_OPC_UA_MASTER_BRANCH ON CACHE BOOL "")
  set(FORTE_COM_OPC_UA_ENCRYPTION_MBEDTLS OFF CACHE BOOL "")

  link_libraries("ssl" "crypto")

  if (WIN32)
    link_libraries(ws2_32 crypt32)
  endif()
endif()

if (FORTE_USE_LUATYPES STREQUAL "LuaJIT")
	set(LUAJIT_LIBRARY "luajit" CACHE STRING "")
endif()

#############################################################################
# Compatibility options / workarounds
#

if (WIN32)
  add_definitions("-D_NO_W32_PSEUDO_MODIFIERS")
endif ()


#############################################################################
# General compiler options
#

if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
  if (TARGET forte)
    add_custom_command(
      OUTPUT forte.stripped
      DEPENDS forte
      COMMAND ${CMAKE_STRIP} src/forte${CMAKE_EXECUTABLE_SUFFIX})
    add_custom_target(strip ALL DEPENDS forte.stripped)
  endif()
endif ()

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

if (FORTE_ARCHITECTURE STREQUAL "FreeRTOSLwIP")
  cmake_policy(SET CMP0079 NEW)
  target_link_libraries(FORTE_LITE freertos::freertos-platform freertos::freertos-core)
  if (FORTE_COM_ETH)
	  if (FORTE_FREERTOS_PLUS_TCP)
		  target_link_libraries(FORTE_LITE freertos::freertos-plus-tcp)
	  else()
		  target_link_libraries(FORTE_LITE freertos::freertos-lwip)
	  endif()
  endif()
endif()
