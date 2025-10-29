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

cmake_minimum_required(VERSION 3.10)
project(forte-fbe CXX)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

# FBE-specific paths and settings, enforced
set(FORTE_COM_CAN_MODULE_CHECK OFF CACHE BOOL "" FORCE)
set(FORTE_MODULE_POWERLINK_LIB_DIR "${CGET_PREFIX}/src/openpowerlink" CACHE STRING "" FORCE)
set(FORTE_MODULE_POWERLINK_TINYXML_DIR "${CGET_PREFIX}/src/tinyxml" CACHE STRING "" FORCE)
set(FORTE_COM_PAHOMQTT_LIB "paho-mqtt3a" CACHE STRING "" FORCE)
set(FORTE_COM_OPC_UA_ENCRYPTION_MBEDTLS OFF CACHE BOOL "" FORCE)

# FBE-specific defaults, can be overridden
set(FORTE_COM_OPC_UA_AC ON CACHE BOOL "")
set(FORTE_COM_OPC_UA_ENCRYPTION ON CACHE BOOL "")
set(FORTE_COM_OPC_UA_Events ON CACHE BOOL "")
set(FORTE_COM_OPC_UA_MULTICAST ON CACHE BOOL "")
if (WIN32 AND CMAKE_SYSTEM_PROCESSOR STREQUAL "i686")
  set(FORTE_WINDOWS_XP_COMPAT ON CACHE BOOL "")
  message(WARNING "The FBE Windows toolchain now uses the UCRT runtime. On Windows 8.1 and earlier, you need to install it manually: https://download.visualstudio.microsoft.com/download/pr/56f631e5-4252-4f28-8ecc-257c7bf412b8/D305BAA965C9CD1B44EBCD53635EE9ECC6D85B54210E2764C8836F4E9DEFA345/VC_redist.x86.exe")
endif ()

# TODO: these should be migrated to build guards in 4diac FORTE
if (NOT LINUX)
  set(FORTE_MODULE_REVOLUTIONPI OFF CACHE BOOL "" FORCE)
endif ()
if (APPLE)
  set(FORTE_COM_SER OFF CACHE BOOL "" FORCE)
  set(FORTE_COM_TSN OFF CACHE BOOL "" FORCE)
endif ()

# make sure to only build and install the forte binary
add_subdirectory($ENV{FBE_FORTE_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/forte EXCLUDE_FROM_ALL)
install(TARGETS forte DESTINATION bin)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  add_custom_target(forte.unstripped ALL DEPENDS forte)
else ()
  add_custom_target(forte.stripped ALL
    DEPENDS forte
    COMMAND ${CMAKE_STRIP} forte/forte${CMAKE_EXECUTABLE_SUFFIX})
endif ()
