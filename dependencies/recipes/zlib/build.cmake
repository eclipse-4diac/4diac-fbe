#********************************************************************************
# Copyright (c) 2018, 2023 OFFIS e.V.
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

cmake_minimum_required(VERSION 3.13)
PROJECT(zlib LANGUAGES C VERSION 1.2.11)

# strip down to bare essentials
file(READ ${CGET_CMAKE_ORIGINAL_SOURCE_FILE} PATCHING)
string(REGEX REPLACE "project\\([^)]*\\)" "" PATCHING "${PATCHING}")
string(REGEX REPLACE "cmake_minimum_required\\([^)]*\\)" "" PATCHING "${PATCHING}")
string(REGEX REPLACE "zlib SHARED " "zlib " PATCHING "${PATCHING}")
string(REGEX REPLACE " \\\${ZLIB_DLL_SRCS} " " " PATCHING "${PATCHING}")
string(REGEX REPLACE "add_executable\\([^)]*\\)" "" PATCHING "${PATCHING}")
string(REGEX REPLACE "add_test\\([^)]*\\)" "" PATCHING "${PATCHING}")
string(REGEX REPLACE "target_link_libraries\\([^)]*\\)" "" PATCHING "${PATCHING}")
string(REGEX REPLACE "target_include_directories\\([^)]*\\)" "" PATCHING "${PATCHING}")
string(REGEX REPLACE "set_target_properties\\((example|minigzip)[^)]*\\)" "" PATCHING "${PATCHING}")
file(WRITE ${CGET_CMAKE_ORIGINAL_SOURCE_FILE} "${PATCHING}")

set(SKIP_INSTALL_ALL ON)
set(SKIP_INSTALL_FILES ON)
set(SKIP_INSTALL_LIBRARIES ON)
include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})
set_target_properties(zlib PROPERTIES OUTPUT_NAME z)
set_target_properties(zlibstatic PROPERTIES OUTPUT_NAME zx)

install(TARGETS zlib EXPORT ${CMAKE_PROJECT_NAME} DESTINATION lib)
install(FILES zlib.h ${CMAKE_CURRENT_BINARY_DIR}/zconf.h DESTINATION include)

include(toolchain-utils)
install_export_config()
