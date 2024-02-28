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

cmake_minimum_required(VERSION 2.8)

set(PAHO_WITH_SSL ON CACHE BOOL "")
set(PAHO_BUILD_STATIC ON CACHE BOOL "")
set(PAHO_BUILD_SHARED OFF CACHE BOOL "")

file(WRITE test/CMakeLists.txt "")

if (WIN32)
  # Windows XP compatibility
  file(WRITE src/windows.h [[
#include <pthread.h>
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#include_next <windows.h>
#define INIT_ONCE pthread_once_t
#undef INIT_ONCE_STATIC_INIT
#define INIT_ONCE_STATIC_INIT PTHREAD_ONCE_INIT
#define InitOnceExecuteOnce(a,b,c,d) (pthread_once(a,(void*)b)==0)
]])
  add_compile_options(-I${CMAKE_CURRENT_SOURCE_DIR}/src)
endif()

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

# override undesired win32 special-case
SET_TARGET_PROPERTIES(paho-mqtt3c-static PROPERTIES OUTPUT_NAME paho-mqtt3c)
SET_TARGET_PROPERTIES(paho-mqtt3a-static PROPERTIES OUTPUT_NAME paho-mqtt3a)
SET_TARGET_PROPERTIES(paho-mqtt3cs-static PROPERTIES OUTPUT_NAME paho-mqtt3cs)
SET_TARGET_PROPERTIES(paho-mqtt3as-static PROPERTIES OUTPUT_NAME paho-mqtt3as)
