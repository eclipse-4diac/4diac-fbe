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

PROJECT(libressl C)
cmake_minimum_required(VERSION 2.8)

include(toolchain-utils)

if (WIN32)
  # build in XP-compatible way
  file(READ ${CGET_CMAKE_ORIGINAL_SOURCE_FILE} patch)
  string(REPLACE "_WIN32_WINNT" "_disabled_WIN32_WINNT" patch "${patch}")
  file(WRITE ${CGET_CMAKE_ORIGINAL_SOURCE_FILE} "${patch}")
  add_compile_definitions(_WIN32_WINNT=0x0501 GetTickCount64=GetTickCount)

  file(REMOVE include/compat/pthread.h)
  file(COPY ${CGET_RECIPE_DIR}/inet_pton.h DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/include/compat/)
  file(COPY ${CGET_RECIPE_DIR}/getentropy_win.c DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/crypto/compat/)
  add_compile_options(-include inet_pton.h -Wno-unused-function)
endif()

option(NO_APPS "only build library")
if (NOT NO_APPS)
  link_libraries(pthread)
endif()


file(GLOB_RECURSE CMAKE_LISTS_FILES CMakeLists.txt)
foreach(FILE ${CMAKE_LISTS_FILES};${CGET_CMAKE_ORIGINAL_SOURCE_FILE})
  file(READ ${FILE} PATCHING)
  # TODO: This probably needs to be patched when cross-compiling
  string(REGEX REPLACE "CMAKE_HOST_" "" PATCHING "${PATCHING}")
  string(REGEX REPLACE "Ws2_32" "ws2_32" PATCHING "${PATCHING}")
  string(REGEX REPLACE "add_subdirectory.man." "" PATCHING "${PATCHING}")
  string(REGEX REPLACE "add_subdirectory.tests." "" PATCHING "${PATCHING}")
  if (NO_APPS)
	string(REGEX REPLACE "add_subdirectory.apps." "" PATCHING "${PATCHING}")
  endif()
  string(REGEX REPLACE "install\\(FILES[^)].* share/man/[^)]*\\)" "" PATCHING "${PATCHING}")
  string(REGEX REPLACE "BUILD_SHARED true" "BUILD_SHARED false" PATCHING "${PATCHING}")
  file(WRITE ${FILE} "${PATCHING}")
endforeach()

set(ENABLE_ASM OFF CACHE BOOL "")
set(ENABLE_NC OFF CACHE BOOL "")

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

# override undesired win32 special-case
set_target_properties(tls PROPERTIES ARCHIVE_OUTPUT_NAME tls)
set_target_properties(ssl PROPERTIES ARCHIVE_OUTPUT_NAME ssl)
set_target_properties(crypto PROPERTIES ARCHIVE_OUTPUT_NAME crypto)
